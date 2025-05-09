# Go Project Cloner

This is a simple app to clone a go project from git repository written in Zig.

## Requirements

- git
- go

## Installation

Just download the release binary from [github](https://github.com/joisandresky/ziggo-cloner/releases), choose the binary that matches your OS and architecture and unzip it. and probably add it to your PATH.

## Usage

```bash
ziggo-cloner --template [repo-url] --name [new-go-mod-name]
```

## How it Works

Basically it will do this:

- Clone the repo (HTTPS/SSH)
- Remove go.sum
- Modify go.mod name
- Recursively rename import paths into new go.mod name
- Run `go mod tidy`
- Reinitialize Git
