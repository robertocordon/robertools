# git-tools

A collection of small command-line tools to make common git workflows faster and less error-prone.

---

# gitmerge

An interactive tool for merging git branches without having to type branch names or remember the right flags.

## What it does

Asks you three questions, then runs the merge for you:

1. **Which branch to merge?** — pick from your local branches using the arrow keys
2. **Which branch to merge into?** — same picker, can't accidentally select the same branch twice
3. **Name of new branch?** — optional; if provided, you'll be checked out to it after the merge

After a successful merge, the source branch is deleted locally (safe delete only — never forced).

## Setup

```bash
chmod +x gitmerge
```

Place it somewhere on your `$PATH`, or run it directly from your repo with `./gitmerge`.

## Usage

```bash
./gitmerge [-i] [-m]
```

With no flags, the tool asks its three questions and runs the merge immediately — no extra prompts.

### Flags

| Flag | Description |
|------|-------------|
| `-i` | **Interactive mode.** Shows a summary of the commands that will run and asks for confirmation before proceeding. |
| `-m` | **Message mode.** Opens your text editor to write a custom merge commit message. Without this flag, the default message is used automatically. |

Flags can be combined: `./gitmerge -i -m`

## Example

```
Which branch to merge?      feature/motor/pwm
Which branch to merge into? develop
Name of new branch?         feature/motor/pins

Done!
Now on branch feature/motor/pins
```

## Notes

- The current branch is marked with a `*` in the branch picker
- The new branch prompt pre-fills with the folder prefix of the source branch (e.g. merging `feature/motor/pwm` pre-fills `feature/motor/`). Backspace on the pre-filled portion removes one path segment at a time.
- Merges always use `--no-ff`
- Branch deletion uses `git branch -d` (safe, never force)

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

