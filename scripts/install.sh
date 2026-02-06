#!/bin/bash

# PlayCamp SDK - Agent Installer
# Installs PlayCamp integration agents for Claude Code
# Usage: bash install.sh [--global|--local] [--platform=node|api|all]

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_OWNER="PlayCamp"
REPO_NAME="playcamp-sdk-agents"
# Allow branch override via --branch argument or BRANCH env var, default to 'main'
BRANCH="main"
PLATFORM="all"  # Default: install all platforms
INSTALL_TYPE="local"  # Default: install to current project

# Parse command-line arguments
for arg in "$@"; do
    case $arg in
        --branch=*)
            BRANCH="${arg#*=}"
            ;;
        --platform=*)
            PLATFORM="${arg#*=}"
            ;;
        --global|-g)
            INSTALL_TYPE="global"
            ;;
        --local|-l)
            INSTALL_TYPE="local"
            ;;
        --uninstall)
            INSTALL_TYPE="uninstall"
            ;;
        --help|-h)
            INSTALL_TYPE="help"
            ;;
    esac
done

# Allow BRANCH environment variable to override (if set)
if [ -n "$BRANCH_ENV" ]; then
    BRANCH="$BRANCH_ENV"
fi

BASE_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}"

# Validate platform argument
case $PLATFORM in
    node|api|all)
        ;;
    *)
        echo -e "${RED}Error: Invalid platform '${PLATFORM}'${NC}"
        echo "Valid options: node, api, all"
        echo "Usage: bash install.sh [--global|--local] [--platform=node|api|all]"
        exit 1
        ;;
esac

# Node SDK agent files
NODE_AGENTS=(
    "playcamp-integrator"
    "playcamp-auditor"
    "playcamp-webhook-specialist"
    "playcamp-migration-assistant"
    "playcamp-test-verifier"
)

# API agent files
API_AGENTS=(
    "playcamp-api-guide"
)

# Helper functions
print_header() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║      PlayCamp SDK Agent Installer            ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    case $PLATFORM in
        node)
            echo -e "  Platform: ${GREEN}Node SDK Agents${NC} (${#NODE_AGENTS[@]} agents)"
            ;;
        api)
            echo -e "  Platform: ${GREEN}API Agents${NC} (${#API_AGENTS[@]} agents)"
            ;;
        all)
            echo -e "  Platform: ${GREEN}All Agents${NC} ($((${#NODE_AGENTS[@]} + ${#API_AGENTS[@]})) agents)"
            ;;
    esac
    echo -e "  Branch:   ${GREEN}${BRANCH}${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

print_info() {
    echo -e "${BLUE}i${NC} $1"
}

# Check if Claude Code is installed (required)
check_claude_code() {
    if command -v claude &> /dev/null; then
        print_success "Claude Code CLI detected"
        return 0
    elif [ -d "$HOME/.claude" ]; then
        print_success "Claude Code directory detected"
        return 0
    else
        print_error "Claude Code is required but not installed"
        echo ""
        echo "   PlayCamp agents require Claude Code to work."
        echo "   Please install Claude Code first, then run this script again."
        echo ""
        echo "   Install Claude Code:"
        echo -e "   - macOS/Linux: ${BLUE}brew install --cask claude-code${NC}"
        echo -e "   - macOS/Linux: ${BLUE}curl -fsSL https://claude.ai/install.sh | bash${NC}"
        echo -e "   - Visit: ${BLUE}https://claude.ai/code${NC}"
        echo ""
        exit 1
    fi
}

# Download a single agent file
download_agent() {
    local agent_name=$1
    local target_dir=$2
    local platform_subdir=$3  # "node" or "api"
    local url="${BASE_URL}/.claude/agents/${platform_subdir}/${agent_name}.md"
    local platform_dir="${target_dir}/${platform_subdir}"
    local target_file="${platform_dir}/${agent_name}.md"

    # Create platform subdirectory if it doesn't exist
    mkdir -p "$platform_dir"

    if curl -fsSL "$url" -o "$target_file" 2>/dev/null; then
        print_success "Downloaded ${agent_name}.md"
        return 0
    else
        print_error "Failed to download ${agent_name}.md from ${url}"
        return 1
    fi
}

# Install agents for a specific platform
install_platform_agents() {
    local target_dir=$1
    local platform_name=$2
    shift 2
    local agents=("$@")  # Remaining arguments are agent names

    print_info "Installing ${platform_name} agents..."

    local success_count=0
    for agent in "${agents[@]}"; do
        if download_agent "$agent" "$target_dir" "$platform_name"; then
            ((success_count++))
        fi
    done

    if [ $success_count -eq ${#agents[@]} ]; then
        print_success "Installed all ${success_count} ${platform_name} agents"
        return 0
    else
        print_error "Only installed ${success_count}/${#agents[@]} ${platform_name} agents"
        return 1
    fi
}

# Install agents globally to ~/.claude/agents/
install_global() {
    local agent_dir="$HOME/.claude/agents"

    print_info "Installing agents globally to ${agent_dir}"
    mkdir -p "$agent_dir"
    echo ""

    local failed=0

    case $PLATFORM in
        node)
            install_platform_agents "$agent_dir" "node" "${NODE_AGENTS[@]}" || failed=1
            ;;
        api)
            install_platform_agents "$agent_dir" "api" "${API_AGENTS[@]}" || failed=1
            ;;
        all)
            install_platform_agents "$agent_dir" "node" "${NODE_AGENTS[@]}" || failed=1
            install_platform_agents "$agent_dir" "api" "${API_AGENTS[@]}" || failed=1
            ;;
    esac

    echo ""
    return $failed
}

# Install agents locally to current project
install_local() {
    local agent_dir=".claude/agents"

    print_info "Installing agents locally to ${agent_dir}"
    mkdir -p "$agent_dir"
    echo ""

    local failed=0

    case $PLATFORM in
        node)
            install_platform_agents "$agent_dir" "node" "${NODE_AGENTS[@]}" || failed=1
            ;;
        api)
            install_platform_agents "$agent_dir" "api" "${API_AGENTS[@]}" || failed=1
            ;;
        all)
            install_platform_agents "$agent_dir" "node" "${NODE_AGENTS[@]}" || failed=1
            install_platform_agents "$agent_dir" "api" "${API_AGENTS[@]}" || failed=1
            ;;
    esac

    echo ""
    return $failed
}

# Verify installation
verify_installation() {
    local agent_dir=$1

    echo ""
    print_info "Verifying installation..."

    local found_count=0
    local total_expected=0

    if [ "$PLATFORM" = "node" ] || [ "$PLATFORM" = "all" ]; then
        total_expected=$((total_expected + ${#NODE_AGENTS[@]}))
        for agent in "${NODE_AGENTS[@]}"; do
            if [ -f "${agent_dir}/node/${agent}.md" ]; then
                ((found_count++))
            fi
        done
    fi

    if [ "$PLATFORM" = "api" ] || [ "$PLATFORM" = "all" ]; then
        total_expected=$((total_expected + ${#API_AGENTS[@]}))
        for agent in "${API_AGENTS[@]}"; do
            if [ -f "${agent_dir}/api/${agent}.md" ]; then
                ((found_count++))
            fi
        done
    fi

    if [ $found_count -eq $total_expected ]; then
        print_success "All ${found_count} agents verified"
        return 0
    else
        print_warning "Found ${found_count}/${total_expected} agents"
        return 1
    fi
}

# Uninstall agents
uninstall_agents() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║      PlayCamp SDK Agent Uninstaller          ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
    echo ""

    local removed=0

    # Remove local agents
    if [ -d ".claude/agents/node" ] || [ -d ".claude/agents/api" ]; then
        print_info "Removing local agents (.claude/agents/)..."
        [ -d ".claude/agents/node" ] && rm -rf ".claude/agents/node" && print_success "Removed .claude/agents/node" && ((removed++))
        [ -d ".claude/agents/api" ] && rm -rf ".claude/agents/api" && print_success "Removed .claude/agents/api" && ((removed++))
    fi

    # Remove global agents
    if [ -d "$HOME/.claude/agents/node" ] || [ -d "$HOME/.claude/agents/api" ]; then
        print_info "Removing global agents (~/.claude/agents/)..."
        [ -d "$HOME/.claude/agents/node" ] && rm -rf "$HOME/.claude/agents/node" && print_success "Removed ~/.claude/agents/node" && ((removed++))
        [ -d "$HOME/.claude/agents/api" ] && rm -rf "$HOME/.claude/agents/api" && print_success "Removed ~/.claude/agents/api" && ((removed++))
    fi

    # Remove routing rules from CLAUDE.md
    remove_routing_rules "CLAUDE.md"
    remove_routing_rules "$HOME/.claude/CLAUDE.md"

    echo ""
    if [ $removed -eq 0 ]; then
        print_warning "No PlayCamp agents found to remove"
    else
        print_success "Uninstall complete"
    fi
}

# PlayCamp routing rules to inject into CLAUDE.md
ROUTING_START="<!-- PLAYCAMP-AGENTS-START -->"
ROUTING_END="<!-- PLAYCAMP-AGENTS-END -->"

ROUTING_RULES="${ROUTING_START}
## PlayCamp Agent Routing (auto-generated by PlayCamp SDK Agent Installer)

When the user requests anything related to PlayCamp SDK — including payment, coupon, sponsor, webhook, integration, or migration — you MUST delegate to the appropriate PlayCamp agent using the Task tool. Do NOT implement PlayCamp integration yourself.

| Request | Agent |
|---------|-------|
| SDK setup, integration, payment, coupon, sponsor API | \`@agent-playcamp-integrator\` |
| Webhook endpoint, event handling, signature verification | \`@agent-playcamp-webhook-specialist\` |
| Code review, audit, security check for PlayCamp code | \`@agent-playcamp-auditor\` |
| Migrate raw HTTP/fetch/axios calls to PlayCamp SDK | \`@agent-playcamp-migration-assistant\` |
| Build verification, config check, environment validation | \`@agent-playcamp-test-verifier\` |
| Direct HTTP API guide (Python, Go, Java, non-Node.js) | \`@agent-playcamp-api-guide\` |
${ROUTING_END}"

# Inject routing rules into CLAUDE.md
inject_routing_rules() {
    local claude_md=$1

    # Skip if already injected
    if [ -f "$claude_md" ] && grep -q "$ROUTING_START" "$claude_md" 2>/dev/null; then
        print_warning "Routing rules already exist in $claude_md (skipped)"
        return 0
    fi

    # Create or append
    if [ -f "$claude_md" ]; then
        printf "\n%s\n" "$ROUTING_RULES" >> "$claude_md"
        print_success "Appended routing rules to $claude_md"
    else
        echo "$ROUTING_RULES" > "$claude_md"
        print_success "Created $claude_md with routing rules"
    fi
}

# Remove routing rules from CLAUDE.md
remove_routing_rules() {
    local claude_md=$1

    if [ ! -f "$claude_md" ]; then
        return 0
    fi

    if ! grep -q "$ROUTING_START" "$claude_md" 2>/dev/null; then
        return 0
    fi

    # Remove everything between START and END markers (inclusive)
    local tmp_file
    tmp_file=$(mktemp)
    awk -v start="$ROUTING_START" -v end="$ROUTING_END" '
        $0 ~ start { skip=1; next }
        $0 ~ end { skip=0; next }
        skip==0 { print }
    ' "$claude_md" > "$tmp_file"

    mv "$tmp_file" "$claude_md"
    print_success "Removed routing rules from $claude_md"
}

# Show usage instructions
show_usage() {
    echo "Usage: bash install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --local               Install agents to current project's .claude/agents/ (default)"
    echo "  --global              Install agents globally to ~/.claude/agents/"
    echo "  --platform=PLATFORM   Choose platform: node, api, or all (default: all)"
    echo "  --branch=BRANCH       Install from specific branch (default: main)"
    echo "  --uninstall           Remove all PlayCamp agents (local and global)"
    echo "  --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  bash install.sh                           # Install all agents locally"
    echo "  bash install.sh --local                   # Install all agents to current project"
    echo "  bash install.sh --global                  # Install all agents globally"
    echo "  bash install.sh --platform=node           # Install only Node SDK agents"
    echo "  bash install.sh --platform=api            # Install only API agents"
    echo "  bash install.sh --global --platform=node  # Install Node agents globally"
}

# Show next steps
show_next_steps() {
    local install_type=$1

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         Installation Complete!         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo "Installed Agents:"

    if [ "$PLATFORM" = "node" ] || [ "$PLATFORM" = "all" ]; then
        echo "   Node SDK:"
        for agent in "${NODE_AGENTS[@]}"; do
            echo "     - ${agent}"
        done
    fi

    if [ "$PLATFORM" = "api" ] || [ "$PLATFORM" = "all" ]; then
        echo "   API:"
        for agent in "${API_AGENTS[@]}"; do
            echo "     - ${agent}"
        done
    fi

    echo ""
    echo "Next Steps:"
    echo ""

    if [ "$INSTALL_TYPE" = "local" ]; then
        echo "1. Launch Claude Code in this project:"
        echo -e "   ${BLUE}claude${NC}"
        echo ""
    else
        echo "1. Navigate to your game server project:"
        echo -e "   ${BLUE}cd /path/to/your/game/server${NC}"
        echo ""
        echo "2. Launch Claude Code:"
        echo -e "   ${BLUE}claude${NC}"
        echo ""
    fi

    echo "3. Ask Claude to integrate PlayCamp SDK:"
    echo ""

    if [ "$PLATFORM" = "node" ] || [ "$PLATFORM" = "all" ]; then
        echo "   Node SDK integration:"
        echo -e "   ${YELLOW}Use @agent-playcamp-integrator to integrate PlayCamp SDK with server key: YOUR_KEY${NC}"
        echo ""
        echo "   Webhook setup:"
        echo -e "   ${YELLOW}Use @agent-playcamp-webhook-specialist to set up webhook endpoints${NC}"
        echo ""
    fi

    if [ "$PLATFORM" = "api" ] || [ "$PLATFORM" = "all" ]; then
        echo "   Direct HTTP API (non-Node.js):"
        echo -e "   ${YELLOW}Use @agent-playcamp-api-guide to integrate PlayCamp via HTTP${NC}"
        echo ""
    fi

    echo "Documentation:"
    echo "   - README: https://github.com/${REPO_OWNER}/${REPO_NAME}/blob/${BRANCH}/README.md"
    echo ""
}

# Main installation flow
main() {
    # Handle help
    if [ "$INSTALL_TYPE" = "help" ]; then
        show_usage
        exit 0
    fi

    # Handle uninstall
    if [ "$INSTALL_TYPE" = "uninstall" ]; then
        uninstall_agents
        exit 0
    fi

    print_header

    # Check prerequisites
    print_info "Checking prerequisites..."

    # Check for curl
    if ! command -v curl &> /dev/null; then
        print_error "curl is required but not installed"
        exit 1
    fi
    print_success "curl detected"

    # Check for Claude Code (required)
    check_claude_code

    echo ""

    # Install agents
    if [ "$INSTALL_TYPE" = "local" ]; then
        if install_local; then
            inject_routing_rules "CLAUDE.md"
            verify_installation ".claude/agents"
            show_next_steps "local"
            exit 0
        else
            exit 1
        fi
    else
        if install_global; then
            inject_routing_rules "$HOME/.claude/CLAUDE.md"
            verify_installation "$HOME/.claude/agents"
            show_next_steps "global"
            exit 0
        else
            exit 1
        fi
    fi
}

# Run main function
main "$@"
