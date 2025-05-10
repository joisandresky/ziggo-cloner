const std = @import("std");
const GitCloner = @import("gitcloner.zig").GitCloner;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Parse arguments
    var template: ?[]const u8 = null;
    var new_mod_name: ?[]const u8 = null;

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        if (std.mem.eql(u8, args[i], "--template") and i + 1 < args.len) {
            template = args[i + 1];
            i += 1;
        } else if (std.mem.eql(u8, args[i], "--name") and i + 1 < args.len) {
            new_mod_name = args[i + 1];
            i += 1;
        }
    }

    const stdout = std.io.getStdOut().writer();
    if (template == null or new_mod_name == null) {
        try stdout.print("Usage: {s} --template <git_url> --name <new_module_name>\n", .{args[0]});
        std.process.exit(1);
    }

    var cloner = GitCloner.init(allocator, stdout.any());

    try cloner.run(template.?, new_mod_name.?);

    try stdout.print("Project cloned and modified successfully!\n", .{});
}
