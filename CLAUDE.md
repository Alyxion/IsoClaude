# Claude Code Instructions for IsoClaude

## Project Overview

IsoClaude is a Docker-based isolated Ubuntu desktop environment for Claude development. It provides a full KDE desktop accessible via browser with persistent storage.

## Key Files

- `isoclaude.sh` - Main control script (up/down/setup/regenerate)
- `setup-container.sh` - Dev tools installer run inside container
- `projects.conf` - User's project mount configuration (gitignored)
- `projects.conf.example` - Template for new users
- `docker-compose.yml` - Generated file (gitignored)

## Commands

```bash
./isoclaude.sh up          # Start container
./isoclaude.sh down        # Stop container
./isoclaude.sh setup       # Install Python/Poetry/Claude
./isoclaude.sh regenerate  # Rebuild compose from projects.conf
```

## Important Notes

### File Generation
- `docker-compose.yml` is auto-generated from `projects.conf`
- Never edit docker-compose.yml directly; edit projects.conf and regenerate

### Persistence
- All volumes persist across down/up cycles
- Only `docker compose down -v` destroys data
- Installed software (apt, pip, npm) persists

### projects.conf Format
```
# /path/to/project:include_git (true/false)
/Users/someone/projects/MyApp:false
```

### Container Details
- Image: `lscr.io/linuxserver/webtop:ubuntu-kde`
- Desktop URL: http://localhost:3000
- Home directory inside container: `/config`
- Projects mount to: `/projects/<folder_name>`

## When Modifying

### Adding Features to isoclaude.sh
- Keep POSIX-compatible bash
- Update help text in `cmd_help()`
- Test with both new and existing setups

### Changing setup-container.sh
- Script runs as root inside container
- Poetry installs to `/config/.local/bin`
- Consider idempotency (script may run multiple times)

### Volume Changes
- Adding new volumes requires `docker compose down -v` to take effect properly
- Document any new volumes in AGENTS.md

## Testing Changes

```bash
# Full reset test
./isoclaude.sh down
docker compose -f docker-compose.yml down -v  # Remove volumes
./isoclaude.sh up
./isoclaude.sh setup
# Verify tools installed

# Persistence test
./isoclaude.sh down
./isoclaude.sh up
docker exec ubuntu-desktop python3.12 --version  # Should work
```

## Don't Commit

These files are gitignored and contain user-specific paths:
- `projects.conf`
- `docker-compose.yml`
