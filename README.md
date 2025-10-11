# Leon Kasdorf’s Dotfiles

This repository contains Leon’s personal Linux dotfiles and a universal setup script that automatically configures a **bare Git repository** for your home directory — including optional installation of **Starship** and **Eza**.

---

## 🚀 Installation (Recommended)

Run this on any new system to set up everything automatically:

```bash
curl -fsSL https://raw.githubusercontent.com/lkasdorf/dotfiles/main/scripts/install_dotfiles_2025.sh |
bash -s -- --ssh --with-tools
```

Optional (without Starship/Eza installation):
```bash
curl -fsSL https://raw.githubusercontent.com/lkasdorf/dotfiles/main/scripts/install_dotfiles_2025.sh |
bash -s -- --ssh
```

### What the Script Does

- Initializes a **bare Git repository** under `~/.dotfiles`
- Connects it automatically to GitHub (`git@github.com:lkasdorf/dotfiles.git`)
- Checks out your tracked files into `$HOME`
- Creates or updates `~/.bash_ssh` (with automatic backup)
- Optionally installs **Starship** (prompt) and **Eza** (modern `ls`)
- Works out of the box on **Debian/Ubuntu/Mint/Zorin**, **Fedora**, and **Arch-based** systems

---

## ⚙️ Bare-Repo Concept and Alias (`config`)

Your Git repository resides in `~/.dotfiles`, and your working tree is your `$HOME` directory.

All Git commands are executed using a dedicated alias:

```bash
alias config='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
```

> This alias is already defined in your `.bash_aliases` file.

This allows you to manage your dotfiles like a normal Git project — without having a `.git` folder inside `$HOME`.

---

## 🧭 Workflow Overview

### Common Commands

| Action | Command |
|--------|----------|
| Check status | `config status` |
| Add file(s) | `config add ~/.bashrc` |
| Commit changes | `config commit -m "update bashrc"` |
| Push to GitHub | `config push` |
| Pull updates | `config pull --rebase` |
| Update submodules | `config submodule update --init --recursive` |
| Show remotes | `config remote -v` |

---

## 🧩 Adding and Tracking Files

### Add a single file
```bash
config add ~/.bash_aliases
config commit -m "alias: added new function foo()"
config push
```

### Add multiple files
```bash
config add ~/.bashrc ~/.bash_ssh ~/.config/starship.toml
config commit -m "shell: rc & starship config"
config push
```

### Add an entire folder (selectively)
```bash
config add ~/.config/nvim/init.lua
config add ~/.config/nvim/lua/
config commit -m "nvim: setup"
config push
```

---

## 🚫 Ignoring Files

To exclude local files from tracking, edit:

```bash
nano ~/.dotfiles/info/exclude
```

Example:
```
.cache/
Downloads/
.local/share/keyrings/
```

This works like `.gitignore`, but only for your local machine.

---

## 🔄 Syncing Changes

### Pull latest updates
```bash
config pull --rebase
```

### Fetch before merging (review incoming commits)
```bash
config fetch --prune
config log --oneline --decorate --graph origin/main..HEAD
```

### Sync submodules
```bash
config submodule sync --recursive
config submodule update --init --recursive
```

---

## ⚔️ Handling Conflicts

If conflicts occur during a pull:

```bash
config status
# Edit conflicted files manually
config add <file>
config rebase --continue
config push
```

---

## 🧰 `.bash_ssh` File

During installation, the script automatically creates `~/.bash_ssh`  
and backs up any existing version as `.bash_ssh.backup-YYYYMMDD-HHMMSS`.

**Default template:**
```bash
# ~/.bash_ssh – personal SSH environment
# Start SSH agent automatically (optional)
# eval "$(ssh-agent -s)" > /dev/null 2>&1
# export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
# alias sshcfg='vim ~/.ssh/config'
```

Use this file to keep SSH-related environment and aliases separate from your main shell config.

---

## 🪄 Starship & Eza Setup

### Starship
A fast, minimal, and elegant shell prompt that shows Git branches, runtime versions, and system state.

- Config file: `~/.config/starship.toml`
- More info: https://starship.rs

### Eza
A modern replacement for `ls` with icons, Git integration, and better color support.

Examples:
```bash
eza -lh --git
eza --tree ~/.config
```

Both tools can be installed automatically with the installer:
```bash
--with-tools
```
or separately:
```bash
--install-starship
--install-eza
```

---

## 🔐 SSH Setup (if needed)

```bash
ssh-keygen -t ed25519 -C "your-github-email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
```

Then go to  
**GitHub → Settings → SSH and GPG Keys → New SSH key**,  
paste the key, and test your connection:

```bash
ssh -T git@github.com
```

---

## 🧠 Troubleshooting

### 🚫 Permission denied (publickey)
Your SSH key is missing or not loaded.  
→ Re-add your SSH key to GitHub and to the agent (see above).

### 🚫 Not a git repository
If `~/.dotfiles` was deleted or corrupted:
```bash
rm -rf ~/.dotfiles
git init --bare ~/.dotfiles
config remote add origin git@github.com:lkasdorf/dotfiles.git
config fetch --prune
config checkout -f origin/main
```

### 🚫 Too many untracked files
Suppress output (already configured by installer):
```bash
config config status.showUntrackedFiles no
```

---

## 🧾 Quick Reference

```bash
# Add / Commit / Push
config add <path>
config commit -m "message"
config push

# Pull / Sync
config pull --rebase
config submodule update --init --recursive
```

---

## 🧩 Typical Use Cases

### Add and push a new file
```bash
config add ~/.config/alacritty/alacritty.yml
config commit -m "add alacritty config"
config push
```

### Remove a file from Git (keep it locally)
```bash
config rm --cached ~/.config/oldtool/config.yml
echo ".config/oldtool/config.yml" >> ~/.gitignore
config add ~/.gitignore
config commit -m "ignore oldtool config"
config push
```

### Remove a file entirely (delete locally, too)
```bash
config rm ~/.bash_old
config commit -m "remove old bash config"
config push
```

---

## 🧰 Global Excludes and Safety Settings

These are automatically set by the installer:

```bash
git config --global --add safe.directory "$HOME/.dotfiles"
config config pull.rebase true
config config fetch.prune true
```

---

## 📦 Supported Linux Distributions

- **Debian / Ubuntu / Linux Mint / Zorin OS / Pop!_OS**
- **Fedora / Nobara**
- **Arch Linux / Manjaro / EndeavourOS / ArcoLinux**

If a package is missing in your distro’s repository,  
the script automatically installs it using a fallback (e.g., Cargo or curl installer).

---

## 📂 Repository Structure

```
dotfiles/
 ├── scripts/
 │   └── install_dotfiles_2025.sh
 ├── .bash_aliases
 ├── .bash_ssh
 ├── .config/
 │   ├── starship.toml
 │   └── nvim/
 └── README.md
```

---

## 💡 Philosophy

This setup follows the **bare-repo** model, which allows all configuration files to live exactly where the system expects them — without symbolic links or duplicated configs.  
It’s clean, portable, and compatible with any Linux distribution.  
Your `$HOME` stays uncluttered, and version control is fully transparent.

---

## 🔒 Security & Reproducibility

For reproducible installs, pin the script to a specific commit:
```bash
curl -fsSL https://raw.githubusercontent.com/lkasdorf/dotfiles/<COMMIT_SHA>/scripts/install_dotfiles_2025.sh | bash -s -- --ssh
```

You can verify integrity via `sha256sum` if desired.

---

## 🧾 License

MIT License © 2025 Leon Kasdorf  
All configurations and scripts are provided “as-is” without warranty.
