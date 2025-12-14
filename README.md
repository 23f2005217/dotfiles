# Dotfiles Manager

A powerful shell script to manage, backup, and restore your Linux configurations with Git branch support. Perfect for maintaining multiple configuration sets (themes, setups) and syncing across machines.

## What It Manages

### Config Files (`~/.config/`)
- **niri** - Window manager configuration
- **rofi** - Application launcher
- **waybar** - Status bar

### Home Configurations
- **`.zshrc`** - Zsh configuration
- **`.oh-my-zsh`** - Oh My Zsh framework and themes

##  Fresh Start Setup

### Prerequisites
1. **Git** - Should be installed
2. **Oh My Zsh** - Install if not present:
   ```bash
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
   ```
3. **zsh-syntax-highlighting** (optional but recommended):
   ```bash
   git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/zsh-syntax-highlighting
   ```

### Initial Setup (New Machine)

1. **Clone this repository:**
   ```bash
   cd ~
   git clone <your-repo-url> dotfiles
   cd dotfiles
   ```

2. **Make the script executable:**
   ```bash
   chmod +x dotfiles-manager.sh
   ```

3. **Install dependencies (zsh-autosuggestions):**
   ```bash
   ./dotfiles-manager.sh install
   ```

4. **Restore your configurations:**
   ```bash
   ./dotfiles-manager.sh restore
   ```
   This will:
   - Restore all configs from the master branch
   - Create backups of existing configs with timestamps
   - Install missing dependencies automatically
   - Reload niri and waybar (if running)

5. **Reload your shell:**
   ```bash
   source ~/.zshrc
   ```

### Initial Backup (Existing Machine)

If you already have configurations and want to start backing them up:

1. **Create the dotfiles directory and initialize Git:**
   ```bash
   mkdir -p ~/dotfiles
   cd ~/dotfiles
   git init
   ```

2. **Add remote (if using GitHub):**
   ```bash
   git remote add origin <your-repo-url>
   ```

3. **Copy the script to the directory and make it executable:**
   ```bash
   # Copy dotfiles-manager.sh to ~/dotfiles/
   chmod +x dotfiles-manager.sh
   ```

4. **First backup:**
   ```bash
   ./dotfiles-manager.sh backup master "Initial backup"
   ```

5. **Push to remote:**
   ```bash
   ./dotfiles-manager.sh push
   ```

##  Detailed Command Guide

### `backup [branch] [message]`
Backs up current configurations to Git.

**Arguments:**
- `branch` (optional) - Git branch name (default: master)
- `message` (optional) - Commit message (default: "Update dotfiles YYYY-MM-DD HH:MM:SS")

**What it does:**
1. Switches to or creates the specified branch
2. Copies configs from `~/.config/` and `~/`
3. Excludes `.git` directories to avoid nested repos
4. Commits changes with the provided message
5. Shows summary of backed up files

**Examples:**
```bash
# Basic backup to master
./dotfiles-manager.sh backup

# Backup to custom branch
./dotfiles-manager.sh backup nord-theme

# Backup with custom message
./dotfiles-manager.sh backup cyberpunk "Add cyberpunk colorscheme"
```

**Use Cases:**
- Daily config backups
- Creating theme variations (one branch per theme)
- Saving different work environments (office, home)

---

### `restore [branch]`
Restores configurations from Git branch.

**Arguments:**
- `branch` (optional) - Branch to restore from (default: master)

**What it does:**
1. Switches to the specified branch
2. Creates timestamped backups of current configs (e.g., `niri.backup.20251214_180000`)
3. Restores all configs from the branch
4. Installs dependencies (zsh-autosuggestions)
5. Reloads niri config and restarts waybar

**Examples:**
```bash
# Restore from master
./dotfiles-manager.sh restore

# Restore from specific branch
./dotfiles-manager.sh restore nord-theme
```

**Use Cases:**
- Switching between themes
- Restoring configs on new machine
- Testing different configurations
- Reverting to previous setup

**Safety:** Always creates backups before overwriting!

---

### `install`
Installs required dependencies for the configurations.

**What it installs:**
- **zsh-autosuggestions** - Auto-completion for zsh commands

**Example:**
```bash
./dotfiles-manager.sh install
```

**Use Cases:**
- Fresh system setup
- After cloning on new machine
- If dependencies were manually removed

---

### `push [branch]`
Pushes branch to remote repository (GitHub).

**Arguments:**
- `branch` (optional) - Branch to push (default: current branch)

**Examples:**
```bash
# Push current branch
./dotfiles-manager.sh push

# Push specific branch
./dotfiles-manager.sh push nord-theme
```

**Use Cases:**
- Syncing to GitHub after backup
- Sharing configs across machines
- Creating backups in cloud

---

### `pull [branch]`
Pulls latest changes from remote repository.

**Arguments:**
- `branch` (optional) - Branch to pull (default: current branch)

**Examples:**
```bash
# Pull current branch
./dotfiles-manager.sh pull

# Pull specific branch
./dotfiles-manager.sh pull master
```

**Use Cases:**
- Syncing changes from another machine
- Getting latest updates from remote
- Team config sharing

---

### `list-branches` (alias: `list`)
Lists all available branches (local and remote).

**Example:**
```bash
./dotfiles-manager.sh list-branches
```

**Output:**
- Shows local branches (current branch in green)
- Shows remote branches

---

### `switch-branch <branch>` (alias: `switch`)
Switches to a different branch without restoring.

**Arguments:**
- `branch` (required) - Branch name to switch to

**Examples:**
```bash
./dotfiles-manager.sh switch-branch cyberpunk
```

**Difference from `restore`:**
- `switch-branch` - Only changes Git branch, doesn't modify configs
- `restore` - Switches branch AND applies configs to system

---

### `status`
Shows current status of the dotfiles repository.

**Example:**
```bash
./dotfiles-manager.sh status
```

**Shows:**
- Current Git branch
- Repository location
- Git status (uncommitted changes)
- List of managed configs with status (✓ present, ✗ missing)

---

### `help`
Displays help information.

**Example:**
```bash
./dotfiles-manager.sh help
```

##  Common Workflows

### Daily Backup Workflow
```bash
cd ~/dotfiles
./dotfiles-manager.sh backup
./dotfiles-manager.sh push
```

### Theme Switching Workflow
```bash
# Create and save new theme
./dotfiles-manager.sh backup dracula-theme "My dracula setup"
./dotfiles-manager.sh push dracula-theme

# Switch to different theme
./dotfiles-manager.sh restore nord-theme
```

### Multi-Machine Sync
**On Machine 1:**
```bash
./dotfiles-manager.sh backup work-setup "Office configuration"
./dotfiles-manager.sh push work-setup
```

**On Machine 2:**
```bash
./dotfiles-manager.sh pull work-setup
./dotfiles-manager.sh restore work-setup
```

### Testing New Config
```bash
# Save current setup first
./dotfiles-manager.sh backup stable "Working config"
./dotfiles-manager.sh push

# Make changes and test...

# If it breaks, restore
./dotfiles-manager.sh restore stable
```

## 🎨 Branch Strategy Examples

- **`master`** - Main/stable configuration
- **`nord-theme`** - Nord colorscheme setup
- **`cyberpunk`** - Cyberpunk theme
- **`work`** - Office/work environment
- **`minimal`** - Lightweight setup for old machines
- **`streaming`** - Setup for streaming/recording

## Important Notes

1. **Backups are automatic** - `restore` always creates timestamped backups
2. **Git directories excluded** - `.git` folders are never backed up (prevents nested repos)
3. **Dependencies auto-install** - `restore` automatically installs zsh-autosuggestions
4. **Configs reload automatically** - Niri and waybar restart after restore

##  Troubleshooting

### "Branch not found"
```bash
# List available branches
./dotfiles-manager.sh list-branches

# Pull from remote if needed
./dotfiles-manager.sh pull
```

### "Failed to push to remote"
```bash
# Check if remote is configured
cd ~/dotfiles
git remote -v

# Add remote if missing
git remote add origin <your-repo-url>
```

### "zsh-autosuggestions not working"
```bash
# Reinstall dependencies
./dotfiles-manager.sh install

# Source zshrc
source ~/.zshrc
```

### Restore old backup
Backups are stored with timestamps:
```bash
# List backups
ls -la ~/.config/*.backup.*
ls -la ~/.*.backup.*

# Manually restore if needed
cp -r ~/.config/niri.backup.20251214_180000 ~/.config/niri
```

## 📝 Customization

To manage additional configs, edit `dotfiles-manager.sh`:

```bash
# For ~/.config/ folders
CONFIGS=("niri" "rofi" "waybar" "kitty" "nvim")

# For ~/ files/folders
HOME_CONFIGS=(".zshrc" ".oh-my-zsh" ".vimrc" ".gitconfig")
```

## 📄 License

Free to use and modify for personal use.
