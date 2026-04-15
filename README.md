# robertools

A collection of small command-line tools to streamline everyday development workflows.

---

## git-tools

A set of tools to make common git workflows faster and less error-prone.

### gitmerge

An interactive tool for merging git branches without having to type branch names or remember the right flags.

#### What it does

Asks you three questions, then runs the merge for you:

1. **Which branch to merge?** — pick from your local branches using the arrow keys
2. **Which branch to merge into?** — same picker, can't accidentally select the same branch twice
3. **Name of new branch?** — optional; if provided, you'll be checked out to it after the merge

After a successful merge, the source branch is deleted locally (safe delete only — never forced).

#### Usage

```bash
./gitmerge [-i] [-m]
```

With no flags, the tool asks its three questions and runs the merge immediately — no extra prompts.

##### Flags

| Flag | Description |
|------|-------------|
| `-i` | **Interactive mode.** Shows a summary of the commands that will run and asks for confirmation before proceeding. |
| `-m` | **Message mode.** Opens your text editor to write a custom merge commit message. Without this flag, the default message is used automatically. |

Flags can be combined: `./gitmerge -i -m`

#### Example

```
Which branch to merge?      feature/motor/pwm
Which branch to merge into? develop
Name of new branch?         feature/motor/pins

Done!
Now on branch feature/motor/pins
```

#### Notes

- The current branch is marked with a `*` in the branch picker
- The new branch prompt pre-fills with the folder prefix of the source branch (e.g. merging `feature/motor/pwm` pre-fills `feature/motor/`). Backspace on the pre-filled portion removes one path segment at a time.
- Merges always use `--no-ff`
- Branch deletion uses `git branch -d` (safe, never force)

---

## commandManager

An interactive command runner and alias manager. Define your frequently-used shell workflows in a config file and run them by name, browse them with arrow keys, or install them as session aliases.

### What it does

Reads a list of named commands from `~/.commandManager` (JSON) and lets you:

1. **Browse and run** — launch with no arguments to pick a command using the arrow keys
2. **Run directly** — pass a command name as a flag to run it immediately
3. **Install aliases** — set shell aliases for the current session so your commands are available by short name
4. **Get help** — list all commands with descriptions, or look up a specific one

### Config file

`~/.commandManager` is a JSON file with two keys:

```json
{
  "install_commands": [
    "echo \"Any setup steps to run during install go here\""
  ],
  "commands": [
    {
      "name": "greet",
      "longName": "Say Hello",
      "helpText": "Prints a greeting and the current date.",
      "commands": ["echo \"Hello!\"", "date"],
      "alias": 1
    }
  ]
}
```

#### Command fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | ✅ | Short identifier, used as the CLI argument and alias name |
| `helpText` | ✅ | Description shown in `--help` output |
| `commands` | ✅ | Array of bash commands — run in sequence |
| `longName` | ➖ | Human-friendly label shown in menus and help output |
| `alias` | ➖ | `1` to alias as `name`, a string to use a custom alias, or `0`/absent for no alias |

### Usage

```bash
./workflow [--install | -i] [--help [name]] [--<name>] [-v]
```

With no arguments, an interactive arrow-key menu is shown.

#### Flags

| Flag | Description |
|------|-------------|
| `--install`, `-i` | Runs `install_commands` in sequence, then sets session aliases for all commands that have an `alias` defined |
| `--help` | Lists all commands with their descriptions |
| `--help <name>` | Shows the description for a single command |
| `--<name>` | Runs the command with that name directly |
| `-v` | **Verbose mode.** Prints each shell command before running it |

### Example

```
$ ./workflow
Select a command: Say Hello (greet)

Running: Say Hello (greet)
Hello!
Tue Apr 14 10:32:01 EDT 2026
```

```
$ ./workflow --help
Available commands:

  Say Hello (greet)            Prints a greeting and the current date.
  List Files (detailed) (listFiles)   Lists all files in the current directory with details.
```

```
$ ./workflow --install -v
Running install steps...
  $ echo "Running install steps..."
  ...
Setting aliases for this session...
  $ alias greet='echo "Hello!" && date'
  $ alias lf='ls -lah'

Done! Aliases are active in this shell session.
```

#### Notes

- Aliases are set in the current shell session only — they do not persist across sessions
- Commands with multiple entries in the `commands` array are joined with `&&` when aliased
- If `~/.commandManager` contains invalid JSON or is missing required fields, a clear error message is shown

---

# Upcoming Tools

## gitrelease

Automates the release process. Creates a release branch off `develop`, appends an entry to the release notes file, then merges into both `develop` and `master`. Tags the resulting commit on `master` with the release version.

## gitundo

Undoes the last commit, leaving your changes intact in the working directory — a safe way to step back without losing work.

## gitrecommit

A shortcut for amending the most recent commit — useful for folding in a small fix or rewording a commit message without creating a new commit.

## gitclean

Discards all unstaged changes. Prompts separately about whether to also discard staged changes, so you never accidentally lose work you meant to keep.

## gitrename

Renames a branch. Defaults to the current branch, or accepts a branch name as an argument to rename any local branch.

