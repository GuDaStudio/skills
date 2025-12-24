#!/bin/bash
# GudaCC Skills Installer
# https://github.com/GuDaStudio/skills

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Available skills
AVAILABLE_SKILLS=("collaborating-with-codex" "collaborating-with-gemini")

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    echo -e "${BLUE}GudaCC Skills Installer${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -u, --user              Install to user-level (~/.claude/skills/)"
    echo "  -p, --project           Install to project-level (./.claude/skills/)"
    echo "  -t, --target <path>     Install to custom target path"
    echo "  -a, --all               Install all available skills"
    echo "  -s, --skill <name>      Install specific skill (can be used multiple times)"
    echo "  -l, --list              List available skills"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --user --all                    # Install all skills to user-level"
    echo "  $0 --project --all                 # Install all skills to current project"
    echo "  $0 --user -s collaborating-with-codex"
    echo "  $0 --target /custom/path --all"
    echo ""
    echo "Available skills:"
    for skill in "${AVAILABLE_SKILLS[@]}"; do
        echo "  - $skill"
    done
}

list_skills() {
    echo -e "${BLUE}Available Skills:${NC}"
    echo ""
    for skill in "${AVAILABLE_SKILLS[@]}"; do
        if [ -d "$SCRIPT_DIR/$skill" ]; then
            echo -e "  ${GREEN}✓${NC} $skill"
        else
            echo -e "  ${RED}✗${NC} $skill (not found in source)"
        fi
    done
}

install_skill() {
    local skill=$1
    local target_dir=$2
    local source_dir="$SCRIPT_DIR/$skill"
    local dest_dir="$target_dir/$skill"

    if [ ! -d "$source_dir" ]; then
        echo -e "${RED}Error: Skill '$skill' not found in source directory${NC}"
        return 1
    fi

    echo -e "${BLUE}Installing${NC} $skill -> $dest_dir"

    # Create target directory
    mkdir -p "$target_dir"

    # Remove existing installation
    if [ -d "$dest_dir" ]; then
        echo -e "${YELLOW}  Removing existing installation...${NC}"
        rm -rf "$dest_dir"
    fi

    # Copy skill directory
    cp -r "$source_dir" "$dest_dir"

    # Remove .git file if it's a submodule reference
    if [ -f "$dest_dir/.git" ]; then
        rm "$dest_dir/.git"
    fi
    find "$dest_dir" -type f -name "*.py" -exec chmod +x {} \;
    echo -e "${GREEN}  ✓ Installed${NC}"
}

# Parse arguments
TARGET_PATH=""
INSTALL_ALL=false
SELECTED_SKILLS=()
SCOPE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--user)
            SCOPE="user"
            TARGET_PATH="$HOME/.claude/skills"
            shift
            ;;
        -p|--project)
            SCOPE="project"
            TARGET_PATH="./.claude/skills"
            shift
            ;;
        -t|--target)
            TARGET_PATH="$2"
            shift 2
            ;;
        -a|--all)
            INSTALL_ALL=true
            shift
            ;;
        -s|--skill)
            SELECTED_SKILLS+=("$2")
            shift 2
            ;;
        -l|--list)
            list_skills
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Validate arguments
if [ -z "$TARGET_PATH" ]; then
    echo -e "${RED}Error: Please specify installation target (-u, -p, or -t)${NC}"
    echo ""
    usage
    exit 1
fi

if [ "$INSTALL_ALL" = false ] && [ ${#SELECTED_SKILLS[@]} -eq 0 ]; then
    echo -e "${RED}Error: Please specify skills to install (-a or -s)${NC}"
    echo ""
    usage
    exit 1
fi

# Determine skills to install
if [ "$INSTALL_ALL" = true ]; then
    SKILLS_TO_INSTALL=("${AVAILABLE_SKILLS[@]}")
else
    SKILLS_TO_INSTALL=("${SELECTED_SKILLS[@]}")
fi

# Validate selected skills
for skill in "${SKILLS_TO_INSTALL[@]}"; do
    valid=false
    for available in "${AVAILABLE_SKILLS[@]}"; do
        if [ "$skill" = "$available" ]; then
            valid=true
            break
        fi
    done
    if [ "$valid" = false ]; then
        echo -e "${RED}Error: Unknown skill '$skill'${NC}"
        echo "Available skills: ${AVAILABLE_SKILLS[*]}"
        exit 1
    fi
done

# Install
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}GudaCC Skills Installer${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Target: ${GREEN}$TARGET_PATH${NC}"
echo -e "Skills: ${GREEN}${SKILLS_TO_INSTALL[*]}${NC}"
echo ""

for skill in "${SKILLS_TO_INSTALL[@]}"; do
    install_skill "$skill" "$TARGET_PATH"
done

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Installation complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
