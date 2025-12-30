# IsoClaude

**An isolated sandbox for running Claude Code in autonomous mode.**

IsoClaude provides a full Ubuntu KDE desktop in Docker specifically designed for running `claude --dangerously-skip-permissions`. Work on long-running AI-assisted development tasks without constant permission interrupts—safely isolated from your host system.

![IsoClaude Desktop](media/desktop-screenshot.png)

## Why IsoClaude?

Claude Code's default behavior asks permission for every command—`mkdir`, `ls`, `git status`. This is safe, but becomes a workflow killer when you want Claude to handle longer tasks autonomously. You set Claude off on a task, walk away for coffee, and come back to find it stopped at step two waiting for approval.

The `--dangerously-skip-permissions` flag (aliased as `clauded` in this environment) solves this by letting Claude run autonomously. But the flag isn't called "dangerously" for nothing.

### Benefits

- **Uninterrupted development**: Let Claude work for hours on complex tasks
- **Full autonomy**: No permission prompts for file operations, git, builds, etc.
- **Ideal for greenfield projects**: Perfect for scaffolding new applications
- **Extended sessions**: Users report successful 9+ hour autonomous coding sessions

### Dangers

- **File deletion**: Claude may remove files it shouldn't touch
- **Scope creep**: Claude sometimes "helps" by modifying files outside your intended scope
- **Data loss**: Datasets, configs, or important files may be overwritten without backup
- **No undo**: Changes happen immediately with no confirmation

**This is why IsoClaude exists**—to give Claude full autonomy inside an isolated container where mistakes can't affect your host system or important data.

## Disclaimer

**USE AT YOUR OWN RISK.** The authors of IsoClaude are not responsible for any data loss, file deletion, system damage, or other issues arising from the use of Claude Code in autonomous mode. Always maintain backups of important data and never mount directories containing sensitive information, credentials, or irreplaceable files.

**Important**: Container isolation only protects local files. Claude can still access and modify resources reachable via network—databases, APIs, cloud services, internal servers. If your environment has network access to production systems, Claude can affect them. Consider network isolation or using test/staging endpoints only.

For official documentation on permissions and settings, see: [Claude Code Settings](https://code.claude.com/docs/en/settings)

## Quick Start

```bash
# 1. Configure your projects
cp projects.conf.example projects.conf
# Edit projects.conf to add your project paths

# 2. Start the container
./isoclaude.sh up

# 3. Install dev tools (first time only)
./isoclaude.sh setup

# 4. Open in browser
open http://localhost:3000
```

## Commands

```bash
./isoclaude.sh up          # Start container
./isoclaude.sh down        # Stop container (data persists)
./isoclaude.sh setup       # Install Python, Poetry, Claude CLI
./isoclaude.sh regenerate  # Regenerate compose after editing projects.conf
```

## Project Mounts

Edit `projects.conf` to mount your local projects into the container:

```
# Format: /path/to/project:include_git
/Users/you/projects/MyApp:false      # Exclude .git
/Users/you/projects/OpenSource:true  # Include .git
```

Projects appear at `/projects/<folder_name>` in the container.

## What's Installed

After running `./isoclaude.sh setup`:
- Python 3.12 + 3.13 with tkinter
- Poetry
- Rust (via rustup)
- Node.js 20
- Claude Code CLI
- VS Code with extensions: Python, Python Debugger, Rust Analyzer, Claude Code
- **`clauded` alias** for `claude --dangerously-skip-permissions`

## Persistence

All data persists across `./isoclaude.sh down` and `up`:
- Installed packages (apt, pip, npm)
- User configuration
- Project files (via mounts)

To completely reset: `docker compose down -v`

## Access

- **Desktop**: http://localhost:3000
- **SSH**: `ssh abc@localhost -p 2222` (password: `isoclaude`)
- **Shell**: `docker exec -it iso-claude-ubuntu bash`

> **Security**: Change the default SSH password after first login with `passwd`

## Best Practices for Autonomous Mode

1. **Scope your tasks clearly**: Specify exactly what needs to be built, which files to focus on, and the expected flow
2. **Work on copies**: Mount project copies, not originals with uncommitted work
3. **Use git**: Ensure projects are under version control so you can revert changes
4. **Avoid sensitive data**: Never mount directories with API keys, credentials, or production configs
5. **Review changes**: Ask Claude to document changes as it works for easier post-review
