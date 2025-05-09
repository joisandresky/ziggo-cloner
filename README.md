# Go Project Cloner

This is a simple script to clone a go project from github written in Zig.

## Requirements

- git
- go

## Installation

Just download the release binary from [github](https://github.com/joisandresky/ziggo-cloner/releases), choose the binary that matches your OS and architecture and unzip it. and probably add it to your PATH.

## Usage

```bash
ziggo-cloner --template [repo-url] --name [project-name-that-will-be-new-go-mod-name]
```

## How it Works

Basically it will do this:

- Clone the repo (HTTPS/SSH)
- Remove go.sum
- Modify go.mod name
- Recursively rename import paths into new go.mod name
- Reinitialize Git
- Run `go mod tidy`
