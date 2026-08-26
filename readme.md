# FireGit

Git hosting built so [Claude Code](https://claude.com/product/claude-code) sessions are automatically committed, pushed, and reversible.

Every agent turn can land as its own commit, with the chat context that produced it. You keep a normal git workflow — clone, branch, push, pull — and FireGit fills in the history you would otherwise have to write by hand.

- Site: [firegit.com](https://firegit.com)
- Docs: [firegit.com/docs](https://firegit.com/docs)
- Discord: [discord.gg/ccrhazF5hp](https://discord.gg/ccrhazF5hp)

This repo ships the **FireGit CLI** (`firegit`). Use it to log in, create and clone repos, and turn on Flame — the Claude Code integration that autocommits and autopushes when a session goes idle.

---

## Install

**macOS / Linux**

```bash
curl -fsSL https://raw.githubusercontent.com/firegitcli/firegit-releases/main/install.sh | bash
```

The installer puts `firegit` in `/usr/local/bin`, or `~/.local/bin` if that isn’t writable. If the install directory isn’t on your `PATH`, add it (the installer will tell you).

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/firegitcli/firegit-releases/main/install.ps1 | iex
```

That installs to `%LOCALAPPDATA%\Programs\firegit` and adds it to your user PATH. Restart the terminal afterward.

Pin a version with `FIREGIT_VERSION` (macOS/Linux) or `$env:FIREGIT_VERSION` (Windows), for example `v0.1.7`. Binaries for every release are on the [Releases](https://github.com/firegitcli/firegit-releases/releases) page (macOS, Linux, and Windows; amd64 and arm64).

Check that it worked:

```bash
firegit version
firegit --help
```

You also need [git](https://git-scm.com) installed. Flame needs [Claude Code](https://claude.com/product/claude-code).

---

## Get started

### 1. Create an account

Sign up at [firegit.com](https://firegit.com) with email, Google, or GitHub. You’ll get a FireGit username — that’s the `owner` in `owner/repo`.

### 2. Log in from the CLI

```bash
firegit auth login
```

Choose **Log in with your browser**, or paste an access token from [firegit.com/settings/tokens](https://firegit.com/settings/tokens).

After login, git clone / push / pull against `firegit.com` just works — you don’t put a token in the remote URL or type a password.

```bash
firegit auth status    # who you’re logged in as
firegit auth logout    # sign out of this machine
```

### 3. Create a repo and push

```bash
firegit repo create hello-world
firegit repo clone your-username/hello-world
cd hello-world
echo hi > README.md && git add . && git commit -m init && git push
```

Repos are private by default. Pass `--public` to create a public one, and optionally `--description` and `--branch`.

Plain git works too, once you’re logged in:

```bash
git clone https://firegit.com/your-username/hello-world.git
git push
git pull
```

### 4. Turn on Flame (optional, for Claude Code)

Flame watches Claude Code and commits (and optionally pushes) when every active session in the repo goes idle — so you don’t end a session sitting on uncommitted edits.

```bash
firegit flame install          # once, for Claude Code on this machine
cd hello-world
firegit flame on               # autocommit + autopush for this repo
```

`firegit repo clone` will offer to install Flame if it detects Claude Code.

That’s the whole loop: account → login → repo → (optional) Flame. Everything else is inspecting history, managing tokens, or toggling Flame.

---

## On the web

[firegit.com](https://firegit.com) is the dashboard for the same repos the CLI talks to.

After you sign in you’ll land on your repos. Open one to:

- Browse files
- Read commits, branches, and tags
- Compare refs
- Watch activity (pushes, including automated Flame pushes)
- Open a per-commit timeline with the captured AI chat for that change
- Change repo settings

Create extra access tokens at [Settings → Tokens](https://firegit.com/settings/tokens) if you want a token for another machine or a read-only pull. Billing (Unlimited) is on the site as well.

---

## Commands

Run `firegit <command> help` (or `-h`) for details. Add `--json` to any command for machine-readable output.

Inside a clone, inspect commands infer the repo from `origin` — same idea as `git log`. Pass a name or `--repo owner/repo` to override.

### Auth

| Command | What it does |
|---|---|
| `firegit auth login` | Log in (browser or pasted token) |
| `firegit auth status` | Show account, username, and token |
| `firegit auth logout` | Sign out of this machine |

### Repos

| Command | What it does |
|---|---|
| `firegit repo create <name>` | Create a repo (`--description`, `--public`, `--branch`) |
| `firegit repo list` | List your repos |
| `firegit repo view <name>` | Show name, visibility, clone URL |
| `firegit repo clone <owner>/<repo> [dir]` | Clone (plain `git clone <url>` also works) |
| `firegit repo delete <name>` | Delete a repo (type the name to confirm; `--yes` to skip) |

Deletes cannot be undone.

### History and activity

| Command | What it does |
|---|---|
| `firegit log [repo]` | Commit log (`--sha`, `--path`, `--page`, `--limit`) |
| `firegit show <sha> [repo]` | One commit and its diff |
| `firegit diff <base> <head> [repo]` | Compare two refs |
| `firegit branch [repo]` | List branches |
| `firegit tag [repo]` | List tags |
| `firegit activity [repo]` | Push and branch activity (`--limit`) |

### Tokens

Tokens are created on the web or by `firegit auth login`. The CLI lists and revokes them.

| Command | What it does |
|---|---|
| `firegit token list` | List access tokens |
| `firegit token revoke <id>` | Revoke a token (asks first) |

Revoking the token this machine logged in with will log it out. Create replacements at [firegit.com/settings/tokens](https://firegit.com/settings/tokens).

### Flame (Claude Code)

Install once per machine, then enable per repo.

| Command | What it does |
|---|---|
| `firegit flame install` | Wire Flame into Claude Code |
| `firegit flame uninstall` | Remove Flame from Claude Code |
| `firegit flame status` | Wiring, plan, sessions, autocommit/autopush for this repo |
| `firegit flame on` | Enable autocommit and autopush (the default) |
| `firegit flame on --commit-only` | Autocommit only — commits stay local |
| `firegit flame off` | Disable autocommit/autopush (hooks stay installed) |
| `firegit flame watch` | Live feed of commits, pushes, and agent turns (esc to stop) |

Bare `firegit flame` is the same as `firegit flame status`.

**How it behaves**

- Commits when a session’s turn ends and every other session in that repo is idle.
- Groups dirty files by the session that last touched them (one agent per commit). Unattributed dirty files go in a separate catch-all commit.
- Then pushes the current branch (unless you used `--commit-only`).
- Never force-commits or force-pushes. A rejected or diverged push is left for you.
- Skips commit and push entirely during a merge, rebase, cherry-pick, or unresolved conflict.
- Does nothing on a clean tree with nothing to push.

If the tree is already dirty when you run `firegit flame on`, FireGit asks whether to commit that work as yours (it happened before Flame was watching) or leave Flame off.

**Free vs Unlimited**

The free plan autocommits/autopushes on **one repo at a time**. `firegit flame on` will offer to switch that slot. [Unlimited](https://firegit.com/pricing) removes the limit.

**One-off overrides** (current shell only)

```bash
FIREGIT_AUTOCOMMIT=0    # don’t commit (and therefore don’t push)
FIREGIT_AUTOPUSH=0      # commit locally, skip the push
```

`firegit flame on --commit-only` is the persisted, per-repo equivalent of `FIREGIT_AUTOPUSH=0`.

---

## Notes

- Git over HTTPS is the supported path. After `firegit auth login`, clone and push with git as usual.
- There are no pull requests or issues — use commits, branches, and the timeline instead.
- Repo deletes are permanent. The CLI makes you type the name unless you pass `--yes`.
- Your FireGit username is assigned at signup.

---

## Help

```bash
firegit --help
firegit <command> help
```

More detail: [firegit.com/docs](https://firegit.com/docs). Questions and feedback: [Discord](https://discord.gg/ccrhazF5hp).
