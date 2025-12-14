#!/bin/bash

# Dotfiles Manager - Backup and restore configurations with branch support
# Usage: ./dotfiles-manager.sh [backup|restore|list-branches|switch-branch]

DOTFILES_DIR="$HOME/dotfiles"
CONFIG_DIR="$HOME/.config"
REMOTE="origin"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurations to manage
CONFIGS=("niri" "rofi" "waybar")

# Home configs to manage (files and directories from home)
HOME_CONFIGS=(".zshrc" ".oh-my-zsh")

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to install dependencies
install_dependencies() {
    print_info "Installing dependencies..."
    
    # Install zsh-autosuggestions if not present
    local zsh_suggestions="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    if [ ! -d "$zsh_suggestions" ]; then
        print_info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_suggestions" || {
            print_error "Failed to install zsh-autosuggestions"
            return 1
        }
        print_success "zsh-autosuggestions installed"
    else
        print_success "zsh-autosuggestions already installed"
    fi
    
    print_success "Dependencies installed"
}

# Function to check if we're in the dotfiles directory
check_dotfiles_dir() {
    if [ ! -d "$DOTFILES_DIR" ]; then
        print_error "Dotfiles directory not found at $DOTFILES_DIR"
        exit 1
    fi
    cd "$DOTFILES_DIR" || exit 1
}

# Function to backup configurations
backup_configs() {
    check_dotfiles_dir
    
    local branch="${1:-master}"
    local commit_msg="${2:-Update dotfiles $(date '+%Y-%m-%d %H:%M:%S')}"
    
    print_info "Starting backup to branch: $branch"
    
    # Switch to or create the branch
    if git show-ref --verify --quiet "refs/heads/$branch"; then
        print_info "Switching to existing branch: $branch"
        git checkout "$branch" 2>/dev/null || {
            print_error "Failed to switch to branch $branch"
            exit 1
        }
    else
        print_info "Creating new branch: $branch"
        git checkout -b "$branch" 2>/dev/null || {
            print_error "Failed to create branch $branch"
            exit 1
        }
    fi
    
    # Copy configurations
    print_info "Copying configurations..."
    for config in "${CONFIGS[@]}"; do
        if [ -d "$CONFIG_DIR/$config" ]; then
            print_info "Backing up $config..."
            rsync -av --delete --exclude='.git' "$CONFIG_DIR/$config/" "$DOTFILES_DIR/$config/" > /dev/null
            print_success "$config backed up"
        else
            print_warning "$config not found in $CONFIG_DIR"
        fi
    done
    
    # Copy home configurations
    print_info "Copying home configurations..."
    for config in "${HOME_CONFIGS[@]}"; do
        if [ -e "$HOME/$config" ]; then
            print_info "Backing up $config..."
            if [ -d "$HOME/$config" ]; then
                rsync -av --delete --exclude='.git' "$HOME/$config/" "$DOTFILES_DIR/$config/" > /dev/null
                # Remove any .git directories that might exist
                find "$DOTFILES_DIR/$config" -name '.git' -type d -exec rm -rf {} + 2>/dev/null || true
            else
                cp "$HOME/$config" "$DOTFILES_DIR/$config"
            fi
            print_success "$config backed up"
        else
            print_warning "$config not found in $HOME"
        fi
    done
    
    # Git operations
    print_info "Committing changes..."
    git add .
    
    if git diff --staged --quiet; then
        print_info "No changes to commit"
    else
        git commit -m "$commit_msg" || {
            print_error "Failed to commit changes"
            exit 1
        }
        print_success "Changes committed: $commit_msg"
    fi
    
    print_success "Backup completed on branch: $branch"
}

# Function to restore configurations
restore_configs() {
    check_dotfiles_dir
    
    local branch="${1:-master}"
    
    print_info "Starting restore from branch: $branch"
    
    # Check if branch exists
    if ! git show-ref --verify --quiet "refs/heads/$branch"; then
        print_error "Branch '$branch' does not exist"
        print_info "Available branches:"
        git branch -a
        exit 1
    fi
    
    # Switch to the branch
    print_info "Switching to branch: $branch"
    git checkout "$branch" 2>/dev/null || {
        print_error "Failed to switch to branch $branch"
        exit 1
    }
    
    # Restore configurations
    print_info "Restoring configurations..."
    for config in "${CONFIGS[@]}"; do
        if [ -d "$DOTFILES_DIR/$config" ]; then
            print_info "Restoring $config..."
            
            # Backup current config
            if [ -d "$CONFIG_DIR/$config" ]; then
                backup_dir="$CONFIG_DIR/${config}.backup.$(date +%Y%m%d_%H%M%S)"
                print_info "Creating backup at $backup_dir"
                cp -r "$CONFIG_DIR/$config" "$backup_dir"
            fi
            
            # Restore from dotfiles
            rsync -av --delete "$DOTFILES_DIR/$config/" "$CONFIG_DIR/$config/" > /dev/null
            print_success "$config restored"
        else
            print_warning "$config not found in dotfiles"
        fi
    done
    
    # Restore home configurations
    print_info "Restoring home configurations..."
    for config in "${HOME_CONFIGS[@]}"; do
        if [ -e "$DOTFILES_DIR/$config" ]; then
            print_info "Restoring $config..."
            
            # Backup current config
            if [ -e "$HOME/$config" ]; then
                backup_path="$HOME/${config}.backup.$(date +%Y%m%d_%H%M%S)"
                print_info "Creating backup at $backup_path"
                cp -r "$HOME/$config" "$backup_path"
            fi
            
            # Restore from dotfiles
            if [ -d "$DOTFILES_DIR/$config" ]; then
                rsync -av --delete "$DOTFILES_DIR/$config/" "$HOME/$config/" > /dev/null
            else
                cp "$DOTFILES_DIR/$config" "$HOME/$config"
            fi
            print_success "$config restored"
        else
            print_warning "$config not found in dotfiles"
        fi
    done
    
    # Install dependencies
    install_dependencies
    
    print_success "Restore completed from branch: $branch"
    print_info "Reloading niri config..."
    niri msg action load-config-file 2>/dev/null && print_success "Niri config reloaded" || print_warning "Could not reload niri config"
    print_info "Restarting waybar..."
    pkill waybar && sleep 0.5 && nohup waybar > /dev/null 2>&1 &
    print_success "Waybar restarted"
}

# Function to push to remote
push_to_remote() {
    check_dotfiles_dir
    
    local branch="${1:-$(git branch --show-current)}"
    
    print_info "Pushing branch '$branch' to remote..."
    
    git push -u "$REMOTE" "$branch" || {
        print_error "Failed to push to remote"
        exit 1
    }
    
    print_success "Pushed to remote: $REMOTE/$branch"
}

# Function to pull from remote
pull_from_remote() {
    check_dotfiles_dir
    
    local branch="${1:-$(git branch --show-current)}"
    
    print_info "Pulling branch '$branch' from remote..."
    
    git pull "$REMOTE" "$branch" || {
        print_error "Failed to pull from remote"
        exit 1
    }
    
    print_success "Pulled from remote: $REMOTE/$branch"
}

# Function to list branches
list_branches() {
    check_dotfiles_dir
    
    local current_branch=$(git branch --show-current)
    
    print_info "Local branches:"
    git branch | while read -r branch; do
        if [[ "$branch" == *"$current_branch"* ]]; then
            echo -e "${GREEN}$branch${NC}"
        else
            echo "$branch"
        fi
    done
    
    echo ""
    print_info "Remote branches:"
    git branch -r
}

# Function to switch branch
switch_branch() {
    check_dotfiles_dir
    
    local branch="$1"
    
    if [ -z "$branch" ]; then
        print_error "Branch name required"
        print_info "Available branches:"
        git branch -a
        exit 1
    fi
    
    print_info "Switching to branch: $branch"
    git checkout "$branch" 2>/dev/null || {
        print_error "Failed to switch to branch $branch"
        exit 1
    }
    
    print_success "Switched to branch: $branch"
}

# Function to show status
show_status() {
    check_dotfiles_dir
    
    local current_branch=$(git branch --show-current)
    
    echo -e "${CYAN}=== Dotfiles Status ===${NC}"
    echo -e "Current branch: ${GREEN}$current_branch${NC}"
    echo -e "Repository: $DOTFILES_DIR"
    echo ""
    
    print_info "Git status:"
    git status --short
    
    echo ""
    print_info "Managed configs:"
    for config in "${CONFIGS[@]}"; do
        if [ -d "$DOTFILES_DIR/$config" ]; then
            echo -e "  ${GREEN}✓${NC} $config"
        else
            echo -e "  ${RED}✗${NC} $config"
        fi
    done
    
    echo ""
    print_info "Managed home configs:"
    for config in "${HOME_CONFIGS[@]}"; do
        if [ -e "$DOTFILES_DIR/$config" ]; then
            echo -e "  ${GREEN}✓${NC} $config"
        else
            echo -e "  ${RED}✗${NC} $config"
        fi
    done
}

# Function to show help
show_help() {
    cat << EOF
${CYAN}Dotfiles Manager${NC} - Backup and restore configurations with branch support

${YELLOW}Usage:${NC}
  ./dotfiles-manager.sh <command> [options]

${YELLOW}Commands:${NC}
  ${GREEN}backup${NC} [branch] [message]     Backup configs to git (default: master)
  ${GREEN}restore${NC} [branch]              Restore configs from git (default: master)
  ${GREEN}install${NC}                       Install dependencies (zsh plugins, etc.)
  ${GREEN}push${NC} [branch]                 Push current/specified branch to remote
  ${GREEN}pull${NC} [branch]                 Pull current/specified branch from remote
  ${GREEN}list-branches${NC}                 List all local and remote branches
  ${GREEN}switch-branch${NC} <branch>        Switch to a different branch
  ${GREEN}status${NC}                        Show current status and managed configs
  ${GREEN}help${NC}                          Show this help message

${YELLOW}Examples:${NC}
  # Backup to master branch
  ./dotfiles-manager.sh backup

  # Backup to custom branch with message
  ./dotfiles-manager.sh backup cyberpunk "Add cyberpunk theme"

  # Restore from a specific branch
  ./dotfiles-manager.sh restore cyberpunk

  # Push current branch to remote
  ./dotfiles-manager.sh push

  # Pull specific branch from remote
  ./dotfiles-manager.sh pull cyberpunk

  # List all branches
  ./dotfiles-manager.sh list-branches

  # Switch to different branch
  ./dotfiles-manager.sh switch-branch nord-theme

${YELLOW}Workflow:${NC}
  1. Create a branch for a config set:   backup <branch-name> "description"
  2. Push to GitHub:                     push <branch-name>
  3. Switch to different setup:          restore <other-branch>
  4. Pull latest changes:                pull <branch-name>

${YELLOW}Managed Configurations:${NC}
$(for config in "${CONFIGS[@]}"; do echo "  • $config"; done)

${YELLOW}Managed Home Configurations:${NC}
$(for config in "${HOME_CONFIGS[@]}"; do echo "  • $config"; done)

EOF
}

# Main script logic
case "$1" in
    backup)
        backup_configs "$2" "$3"
        ;;
    restore)
        restore_configs "$2"
        ;;
    install)
        install_dependencies
        ;;
    push)
        push_to_remote "$2"
        ;;
    pull)
        pull_from_remote "$2"
        ;;
    list-branches|list)
        list_branches
        ;;
    switch-branch|switch)
        switch_branch "$2"
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
