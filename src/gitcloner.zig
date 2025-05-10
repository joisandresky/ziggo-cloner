const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub const GitCloner = struct {
    allocator: Allocator,
    writer: std.io.AnyWriter,
    template_url: []const u8 = undefined,
    new_mod: []const u8 = undefined,

    pub fn init(allocator: Allocator, writer: std.io.AnyWriter) GitCloner {
        return GitCloner{
            .allocator = allocator,
            .writer = writer,
        };
    }

    pub fn run(self: *GitCloner, template_url: []const u8, new_mod: []const u8) !void {
        self.template_url = template_url;
        self.new_mod = new_mod;

        const new_folder_name = try self.getNewFolderName(self.new_mod);
        defer self.allocator.free(new_folder_name);

        try self.runCommand(&[_][]const u8{ "git", "clone", self.template_url, new_folder_name });

        try std.posix.chdir(new_folder_name);
        defer std.posix.chdir("..") catch {};

        const old_mod_name = try self.getOldModName("go.mod");
        defer if (old_mod_name) |name| self.allocator.free(name);

        try self.removeFileIfExists("go.sum");

        try self.rewriteGoModModuleName(self.new_mod);

        if (old_mod_name) |old_name| {
            try self.updateImports(old_name, self.new_mod);
        }

        try self.runCommand(&[_][]const u8{ "go", "mod", "tidy" });

        try self.reinitializeGit();
    }

    fn getNewFolderName(self: *GitCloner, new_mod_name: []const u8) ![]u8 {
        const last_slash = std.mem.lastIndexOf(u8, new_mod_name, "/") orelse return try self.allocator.dupe(u8, new_mod_name);

        return try self.allocator.dupe(u8, new_mod_name[last_slash + 1 ..]);
    }

    fn runCommand(self: *GitCloner, args: []const []const u8) !void {
        var child = std.process.Child.init(args, self.allocator);
        child.stdout_behavior = .Inherit;
        child.stderr_behavior = .Inherit;
        const term = try child.spawnAndWait();
        if (term.Exited != 0) {
            return error.CommandFailed;
        }
    }

    fn removeFileIfExists(_: *GitCloner, path: []const u8) !void {
        std.fs.cwd().deleteFile(path) catch |err| {
            if (err != error.FileNotFound) return err;
        };
    }

    fn rewriteGoModModuleName(self: *GitCloner, new_mod: []const u8) !void {
        const file = try std.fs.cwd().openFile("go.mod", .{});
        defer file.close();

        const content = try file.readToEndAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(content);

        var new_content = ArrayList(u8).init(self.allocator);
        defer new_content.deinit();

        var lines = std.mem.splitAny(u8, content, "\n");
        while (lines.next()) |line| {
            if (std.mem.startsWith(u8, line, "module ")) {
                const updated_line = try std.fmt.allocPrint(self.allocator, "module {s}", .{new_mod});
                try new_content.appendSlice(updated_line);
                self.allocator.free(updated_line);
            } else {
                try new_content.appendSlice(line);
            }
            try new_content.append('\n');
        }

        const out_file = try std.fs.cwd().createFile("go.mod", .{ .truncate = true });
        defer out_file.close();
        try out_file.writeAll(new_content.items);
    }

    fn getOldModName(self: *GitCloner, path: []const u8) !?[]u8 {
        const file = std.fs.cwd().openFile(path, .{}) catch |err| {
            if (err == error.FileNotFound) return null;
            return err;
        };
        defer file.close();

        const content = try file.readToEndAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(content);

        var lines = std.mem.splitAny(u8, content, "\n");
        while (lines.next()) |line| {
            if (std.mem.startsWith(u8, line, "module ")) {
                return try self.allocator.dupe(u8, line[7..]);
            }
        }
        return null;
    }

    fn updateImports(self: *GitCloner, old_mod: []const u8, new_mod: []const u8) !void {
        var dir = try std.fs.cwd().openDir(".", .{
            .iterate = true,
            .access_sub_paths = true,
        });
        defer dir.close();

        var walker = try dir.walk(self.allocator);
        defer walker.deinit();

        while (try walker.next()) |entry| {
            if (entry.kind == .file and std.mem.endsWith(u8, entry.path, ".go")) {
                try self.writer.print("Updating imports in: {s}\n", .{entry.path});
                try self.updateFileImports(entry.path, old_mod, new_mod);
            }
        }
    }

    fn updateFileImports(self: *GitCloner, path: []const u8, old_mod: []const u8, new_mod: []const u8) !void {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        const content = try file.readToEndAlloc(self.allocator, 1024 * 1024);
        defer self.allocator.free(content);

        var new_content = ArrayList(u8).init(self.allocator);
        defer new_content.deinit();

        var lines = std.mem.splitAny(u8, content, "\n");
        while (lines.next()) |line| {
            if (std.mem.indexOf(u8, line, old_mod)) |_| {
                const new_line = try std.mem.replaceOwned(u8, self.allocator, line, old_mod, new_mod);
                try new_content.appendSlice(new_line);
                self.allocator.free(new_line);
            } else {
                try new_content.appendSlice(line);
            }
            try new_content.append('\n');
        }

        const out_file = try std.fs.cwd().createFile(path, .{ .truncate = true });
        defer out_file.close();
        try out_file.writeAll(new_content.items);
    }

    fn reinitializeGit(self: *GitCloner) !void {
        std.fs.cwd().deleteTree(".git") catch |err| {
            if (err != error.FileNotFound) return err;
        };

        try self.runCommand(&[_][]const u8{ "git", "init" });
    }
};
