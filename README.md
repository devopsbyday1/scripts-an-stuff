# scripts-an-stuff

A collection of handy shell scripts for everyday dev and ops tasks.

## Scripts

| Script | Description |
|--------|-------------|
| [git-branch-selector.sh](git-branch-selector.sh) | Search for and checkout git branches interactively. Fetches latest from remote, detects the default branch, and handles uncommitted changes. |
| [dns-checker.sh](dns-checker.sh) | Validate DNS records against expected values from an input file. Color-coded output with a non-zero exit code on failure, suitable for CI/CD pipelines. |

## Quick Start

```bash
# Make scripts executable
chmod +x *.sh

# Search for a git branch and check it out
./git-branch-selector.sh feature

# Validate DNS entries from a file
./dns-checker.sh dns-entries.txt
```

## Requirements

- **bash** 4.0+
- **git** (for git-branch-selector.sh)
- **dig** from `dnsutils` / `bind-utils` (for dns-checker.sh)

## License

Licensed under the [GNU General Public License v3.0](LICENSE).
