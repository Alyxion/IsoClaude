#!/bin/bash
# Claude Project Launcher - Interactive project selector for IsoClaude
# Shows projects table and launches Claude in selected project
#
# Usage: ./claude-launch.sh [claude-options]
# Examples:
#   ./claude-launch.sh                    # Interactive mode selection
#   ./claude-launch.sh --resume           # Resume previous conversation
#   ./claude-launch.sh --continue         # Continue with last session
#   ./claude-launch.sh -p "fix the bug"   # Start with a prompt

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECTS_CONF="$SCRIPT_DIR/projects.conf"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
CONTAINER_NAME="iso-claude-ubuntu"

# Capture any extra arguments to pass to claude
EXTRA_ARGS=("$@")

# Colors
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
RESET='\033[0m'

# Check if projects.conf is newer than docker-compose.yml
conf_changed() {
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        return 0
    fi
    if [[ ! -f "$PROJECTS_CONF" ]]; then
        return 1
    fi
    [[ "$PROJECTS_CONF" -nt "$COMPOSE_FILE" ]]
}

# Auto-regenerate and restart if conf changed
auto_regenerate() {
    if conf_changed; then
        echo -e "${YELLOW}Detected changes in projects.conf, regenerating...${RESET}"
        "$SCRIPT_DIR/isoclaude.sh" regenerate
        # If container is running, restart it to apply changes
        if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            echo -e "${YELLOW}Restarting container to apply changes...${RESET}"
            "$SCRIPT_DIR/isoclaude.sh" down
            "$SCRIPT_DIR/isoclaude.sh" up
        fi
    fi
}

# Check if container is running, start if not
check_container() {
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo -e "${YELLOW}Container '$CONTAINER_NAME' is not running. Starting...${RESET}"
        "$SCRIPT_DIR/isoclaude.sh" up
        # Wait for container to be fully ready
        echo -n "Waiting for container to be ready"
        for i in {1..30}; do
            if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
                echo -e " ${GREEN}ready${RESET}"
                return 0
            fi
            echo -n "."
            sleep 1
        done
        echo -e "\n${RED}Error: Container failed to start${RESET}"
        exit 1
    fi
}

# Parse projects.conf and build arrays
declare -a PROJECT_NAMES
declare -a PROJECT_PATHS
declare -a PROJECT_GIT

parse_projects() {
    local idx=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue

        # Parse path:include_git
        local path="${line%%:*}"
        local include_git="${line##*:}"
        local folder_name="$(basename "$path")"

        PROJECT_NAMES[$idx]="$folder_name"
        PROJECT_PATHS[$idx]="/projects/$folder_name"
        PROJECT_GIT[$idx]="$include_git"
        ((idx++))
    done < "$PROJECTS_CONF"
}

# Arrow key menu selection
# Usage: arrow_select "Title" selected_index item1 item2 ...
# Returns: sets SELECTED_IDX to chosen index
arrow_select() {
    local title="$1"
    shift
    local items=("$@")
    local count=${#items[@]}
    local current=0

    # Hide cursor
    tput civis
    trap 'tput cnorm' EXIT

    while true; do
        # Clear and redraw
        tput clear
        echo ""
        echo -e "${BOLD}$title${RESET}"
        echo -e "${CYAN}Use ↑/↓ arrows to navigate, Enter to select${RESET}"
        echo ""

        for i in "${!items[@]}"; do
            if [[ $i -eq $current ]]; then
                echo -e "  ${GREEN}▶ ${items[$i]}${RESET}"
            else
                echo -e "    ${items[$i]}"
            fi
        done

        # Read single keypress
        read -rsn1 key

        # Handle arrow keys (escape sequences)
        if [[ "$key" == $'\x1b' ]]; then
            read -rsn2 key
            case "$key" in
                '[A') # Up arrow
                    ((current--))
                    [[ $current -lt 0 ]] && current=$((count - 1))
                    ;;
                '[B') # Down arrow
                    ((current++))
                    [[ $current -ge $count ]] && current=0
                    ;;
            esac
        elif [[ "$key" == "" ]]; then
            # Enter pressed
            SELECTED_IDX=$current
            tput cnorm
            return
        fi
    done
}

# Select project with arrow keys
select_project() {
    local max=${#PROJECT_NAMES[@]}

    if [[ $max -eq 0 ]]; then
        echo -e "${RED}No projects configured in projects.conf${RESET}"
        exit 1
    fi

    # Build display items
    local items=()
    for i in "${!PROJECT_NAMES[@]}"; do
        local git_status
        if [[ "${PROJECT_GIT[$i]}" == "true" ]]; then
            git_status="${GREEN}git:connected${RESET}"
        else
            git_status="${YELLOW}git:isolated${RESET}"
        fi
        items+=("$(printf "%-25s %s" "${PROJECT_NAMES[$i]}" "$git_status")")
    done

    arrow_select "Select Project" "${items[@]}"
}

# Select mode with arrow keys
select_mode() {
    local items=(
        "Normal mode (safe)"
        "${RED}Dangerous mode (--dangerously-skip-permissions)${RESET}"
    )

    arrow_select "Select Launch Mode" "${items[@]}"

    if [[ $SELECTED_IDX -eq 0 ]]; then
        CLAUDE_MODE=""
    else
        CLAUDE_MODE="--dangerously-skip-permissions"
    fi
}

# Launch Claude
launch_claude() {
    local project_name="${PROJECT_NAMES[$PROJECT_IDX]}"
    local project_path="${PROJECT_PATHS[$PROJECT_IDX]}"

    tput clear
    echo ""
    echo -e "${GREEN}Launching Claude in ${BOLD}$project_name${RESET}${GREEN}...${RESET}"

    if [[ -n "$CLAUDE_MODE" ]]; then
        echo -e "${YELLOW}Mode: DANGEROUS (skipping permissions)${RESET}"
    else
        echo -e "Mode: Normal"
    fi

    # Show extra arguments if any
    if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
        echo -e "Args: ${EXTRA_ARGS[*]}"
    fi
    echo ""

    # Build the full command with mode and extra args
    local claude_cmd="claude $CLAUDE_MODE ${EXTRA_ARGS[*]}"

    # Launch as 'abc' user (non-root) - required for dangerous mode
    # The abc user is the standard user in linuxserver images
    # Set HOME and source profile to ensure proper PATH
    docker exec -it -u abc -e HOME=/config -w "$project_path" "$CONTAINER_NAME" \
        /bin/bash -c "source /etc/profile.d/poetry.sh 2>/dev/null; source ~/.bashrc 2>/dev/null; $claude_cmd"
}

# Main
main() {
    auto_regenerate
    check_container
    parse_projects
    select_project
    PROJECT_IDX=$SELECTED_IDX
    select_mode
    launch_claude
}

main
