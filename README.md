# IsoClaude

**Unleash Claude's full potential. No interruptions. No limits. Complete isolation.**

IsoClaude is a sandboxed Ubuntu environment that lets you run Claude Code in fully autonomous mode—where AI handles everything from file creation to git commits without asking permission for every command.

![IsoClaude Desktop](media/desktop-screenshot.png)

## The Problem

Claude Code asks permission for everything. `mkdir`? Permission. `ls`? Permission. `git status`? You guessed it.

You set Claude off on a task, walk away for coffee, and come back to find it stopped at step two—waiting for you to approve creating a directory.

Even with a carefully tuned `settings.json` allowlist, there are always edge cases. Some commands can't be pre-approved. Variations slip through. You're constantly interrupted.

## The Solution

IsoClaude gives Claude a full Ubuntu desktop where it can work autonomously—safely isolated from your host system. Your real files, your git history, your system configs? Untouchable. Claude gets a sandbox. You get your time back.

**What people are doing with IsoClaude:**
- 9+ hour autonomous coding sessions building entire features
- Greenfield project scaffolding from a single prompt
- Complex refactoring across dozens of files
- CI/CD pipeline development and testing
- Dependency upgrades with test verification

## Installation

Add IsoClaude to your shell so you can run it from anywhere:

**macOS (zsh):**
```bash
echo 'alias isoclaude="/path/to/IsoClaude/isoclaude.sh"' >> ~/.zshrc
source ~/.zshrc
```

**Linux (bash):**
```bash
echo 'alias isoclaude="/path/to/IsoClaude/isoclaude.sh"' >> ~/.bashrc
source ~/.bashrc
```

Replace `/path/to/IsoClaude` with your actual path. After this, use `isoclaude` instead of `./isoclaude.sh`.

## Quick Start

```bash
# 1. Add your first project
isoclaude projects:add ~/projects/MyApp

# 2. Start the container
isoclaude up

# 3. Open desktop in browser
isoclaude browser

# 4. Install dev tools (first time only)
isoclaude setup

# 5. Launch Claude
isoclaude claude
```

That's it. Select your project, choose dangerous mode, and let Claude work.

## Launching Claude

```bash
# From within a project directory (auto-detects, just asks for mode)
cd ~/projects/MyApp
isoclaude claude                    # Detects MyApp, asks Normal/Dangerous
isoclaude claude --resume           # Resume previous conversation
isoclaude claude -p "build a REST API"  # Start with a prompt

# From elsewhere (shows project picker first)
isoclaude claude                    # Pick project, then mode
```

The launcher:
1. Auto-starts the container if not running
2. Auto-detects project if you're inside a configured project directory
3. Shows project picker only when needed
4. Lets you choose Normal or Dangerous mode
5. Passes any extra arguments directly to Claude

Use arrow keys to navigate, Enter to select.

## Project Management

```bash
# List configured projects
isoclaude projects:list

# Add project (excludes .git by default, chrome enabled by default)
isoclaude projects:add ~/projects/MyApp

# Add/update with git access (for commits/pushes)
isoclaude projects:add ~/projects/MyApp --git true

# Disable chrome MCP for a project
isoclaude projects:add ~/projects/MyApp --chrome false

# Combine flags
isoclaude projects:add ~/projects/MyApp --git true --chrome true

# Remove by name or path
isoclaude projects:remove MyApp
```

Changes auto-apply on the next command that uses the container.

Projects mount to `/projects/<folder_name>` inside the container.

### Git Isolation

By default, IsoClaude excludes `.git` folders—Claude works on your code but can't mess with your commit history. Set `--git true` when you want Claude to make commits.

### Chrome MCP

By default, Chrome browser automation is enabled (`--chrome true`). This adds `--mcp claude-in-chrome` when launching Claude, allowing browser control capabilities. Set `--chrome false` to disable.

### CPU Architecture

IsoClaude supports two independent environments that can run in parallel:

```bash
# Show status of both environments
isoclaude arch

# Switch active environment to amd64
isoclaude arch amd64
isoclaude up

# Switch back to native
isoclaude arch native
isoclaude up
```

| Environment | Desktop | SSH | HTTP | Description |
|------------|---------|-----|------|-------------|
| **native** | :3000 | :2222 | :8090 | Host CPU (faster) |
| **amd64** | :3100 | :2322 | :8190 | x86_64 emulated |

Both environments have completely separate volumes and can run simultaneously.
Setup runs automatically on first use of each environment.

### Claude in Chrome Extension

The [Claude in Chrome](https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn) extension is pre-installed. On first use:

1. Open Chrome in the desktop (http://localhost:3000)
2. Click the Claude extension icon in the toolbar
3. Log in to your Claude account (Pro, Max, Team, or Enterprise required)

Your login persists across container restarts. Once connected, Claude Code can:
- Navigate websites, click buttons, fill forms
- Read console logs and network requests for debugging
- Take screenshots to verify UI changes
- Test your web apps running in the container
- Run multi-step browser workflows autonomously

This creates a powerful build-test-verify loop: Claude Code builds your app, then uses the browser to test it and debug issues—all without leaving the terminal.

## Commands

| Command | Description |
|---------|-------------|
| `isoclaude up` | Start the container |
| `isoclaude down` | Stop the container (data persists) |
| `isoclaude restart` | Rebuild container with current config |
| `isoclaude setup` | Install Python, Poetry, Rust, Node, Claude CLI |
| `isoclaude browser [url]` | Open desktop in browser (default: localhost:3000) |
| `isoclaude bash [project]` | Bash shell in project (auto-detects from cwd) |
| `isoclaude code [project]` | VS Code remote to project (auto-detects from cwd) |
| `isoclaude windsurf [project]` | Windsurf remote to project (auto-detects from cwd) |
| `isoclaude claude [args]` | Launch Claude in a project |
| `isoclaude projects:list` | Show configured projects |
| `isoclaude projects:add` | Add a project mount |
| `isoclaude projects:remove` | Remove a project mount |
| `isoclaude arch` | Show status of both environments |
| `isoclaude arch native` | Switch to native (faster, default) |
| `isoclaude arch amd64` | Switch to amd64 (x86_64 emulated) |
| `isoclaude regenerate` | Rebuild docker-compose.yml |

The `bash`, `code`, `windsurf`, and `claude` commands auto-detect the project if you're inside a configured project directory. Otherwise, they show an interactive picker.

## Port Mappings

Applications running inside the container are accessible on your host:

| Service | Container | Native Host | AMD64 Host |
|---------|-----------|-------------|------------|
| Desktop (noVNC) | 3000 | 3000 | 3100 |
| SSH | 22 | 2222 | 2322 |
| Python/NiceGUI HTTP | 8080 | 8090 | 8190 |
| Python/NiceGUI HTTPS | 8443 | 8453 | 8553 |
| Streamlit | 8501 | 8511 | 8611 |
| Node.js | 3001 | 3010 | 3110 |
| Flask | 5000 | 5010 | 5110 |

Example: Run NiceGUI on port 8080, access at `localhost:8090` (native) or `localhost:8190` (amd64)

## What's Installed

After `./isoclaude.sh setup`:

- **Python** 3.12 + 3.13 with tkinter
- **Poetry** for dependency management
- **Rust** via rustup
- **Node.js** 20 + npm
- **Claude Code CLI** with `clauded` alias
- **VS Code** with Python, Rust Analyzer, and Claude Code extensions
- **Claude in Chrome** extension (log in on first use, credentials persist)

## Access Methods

| Method | Address | Notes |
|--------|---------|-------|
| Desktop | http://localhost:3000 | Full KDE in browser |
| SSH | `ssh abc@localhost -p 2222` | Password: `isoclaude` |
| Shell | `isoclaude bash` | Direct access |

> **First thing**: Change the default SSH password with `passwd`

### IDE Integration (VS Code / Windsurf)

Connect your local IDE to projects inside the container:

```bash
# From within a project directory (auto-detects project)
cd ~/projects/MyApp
isoclaude code              # Opens VS Code
isoclaude windsurf          # Opens Windsurf

# Or specify project explicitly
isoclaude code MyApp
isoclaude windsurf MyApp
```

Requires the "Remote - SSH" extension installed in your IDE.

**CLI Setup** (if `code` or `windsurf` commands aren't found):

**macOS:**
```bash
# VS Code: Install "Shell Command: Install 'code' command in PATH" from Command Palette
# Windsurf:
export PATH="$PATH:/Applications/Windsurf.app/Contents/Resources/app/bin"
```

**Windows (add to PATH):**
```
%LOCALAPPDATA%\Programs\Windsurf\resources\app\bin
```

**Linux:**
```bash
export PATH="$PATH:/opt/Windsurf/resources/app/bin"
```

## Persistence

Everything survives restarts:
- Installed packages (apt, pip, npm, cargo)
- VS Code extensions and settings
- Chrome/Chromium profiles and login credentials
- Claude conversation history
- Your project files (mounted from host)

To completely reset: `docker compose down -v`

## Best Practices

1. **Be specific** — "Build a REST API with user auth using FastAPI and SQLAlchemy" beats "make an API"
2. **Use project copies** — Mount copies of projects, not originals with uncommitted work
3. **Git everything** — Even with `.git` excluded, your host copy has version control
4. **Avoid secrets** — Don't mount directories with API keys or credentials
5. **Ask for documentation** — Tell Claude to document changes as it works

## Network Warning

Container isolation protects local files. It does **not** protect:
- Databases Claude can reach over the network
- APIs with credentials Claude has access to
- Cloud services, internal servers, production systems

If your container can reach it, Claude can affect it. Use test environments.

## Disclaimer

**USE AT YOUR OWN RISK.** The authors are not responsible for data loss, deleted files, or other damage from running Claude in autonomous mode. The `--dangerously-skip-permissions` flag is named that way for a reason.

Always maintain backups. Never mount irreplaceable data.

---

For Claude Code documentation: [claude.ai/code](https://claude.ai/code)
