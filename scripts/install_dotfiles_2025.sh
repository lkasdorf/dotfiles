#!/usr/bin/env bash
set -euo pipefail

REPO_URL_DEFAULT_SSH="git@github.com:lkasdorf/dotfiles.git"
REPO_URL_DEFAULT_HTTPS="https://github.com/lkasdorf/dotfiles.git"
REPO_URL="${REPO_URL_DEFAULT_SSH}"

DOTDIR="${HOME}/.dotfiles"
WORKTREE="${HOME}"
BACKUP_DIR="${HOME}/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

INSTALL_STARSHIP=false
INSTALL_EZA=false

usage() {
  cat <<EOF
Usage: $0 [--ssh|--https] [--repo URL] [--dotdir PATH] [--worktree PATH]
            [--install-starship] [--install-eza] [--with-tools]
  --ssh / --https        Remote-Protokoll (Default: SSH)
  --repo URL             Explizite Remote-URL
  --dotdir PATH          Bare-Repo-Verzeichnis (Default: ~/.dotfiles)
  --worktree PATH        Worktree (Default: ~)
  --install-starship     Starship installieren
  --install-eza          eza installieren
  --with-tools           installiert Starship UND eza
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ssh) REPO_URL="${REPO_URL_DEFAULT_SSH}"; shift ;;
    --https) REPO_URL="${REPO_URL_DEFAULT_HTTPS}"; shift ;;
    --repo) REPO_URL="${2}"; shift 2 ;;
    --dotdir) DOTDIR="${2}"; shift 2 ;;
    --worktree) WORKTREE="${2}"; shift 2 ;;
    --install-starship) INSTALL_STARSHIP=true; shift ;;
    --install-eza) INSTALL_EZA=true; shift ;;
    --with-tools) INSTALL_STARSHIP=true; INSTALL_EZA=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unbekannter Parameter: $1"; usage; exit 2 ;;
  esac
done

echo ">>> Repo: ${REPO_URL}"
echo ">>> DOTDIR: ${DOTDIR}"
echo ">>> WORKTREE: ${WORKTREE}"
echo ">>> Extras: starship=${INSTALL_STARSHIP} eza=${INSTALL_EZA}"

command -v git >/dev/null 2>&1 || { echo "git fehlt."; exit 1; }

SUDO=""; command -v sudo >/dev/null 2>&1 && SUDO="sudo"

# --- Distribution erkennen ---
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  DISTRO_ID="${ID:-unknown}"
else
  DISTRO_ID="unknown"
fi

pm_update() {
  case "$DISTRO_ID" in
    debian|ubuntu|linuxmint|zorin|pop) $SUDO apt-get update -y ;;
    fedora) $SUDO dnf -y makecache ;;
    arch|manjaro|endeavouros|arco) $SUDO pacman -Sy --noconfirm ;;
  esac || true
}
pm_install() {
  case "$DISTRO_ID" in
    debian|ubuntu|linuxmint|zorin|pop) $SUDO apt-get install -y $1 ;;
    fedora) $SUDO dnf install -y $1 ;;
    arch|manjaro|endeavouros|arco) $SUDO pacman -S --noconfirm --needed $1 ;;
  esac || return 1
}

ensure_rustup() {
  if ! command -v cargo >/dev/null 2>&1; then
    echo ">>> Installiere rustup…"
    curl -fsSL https://sh.rustup.rs | sh -s -- -y
    . "$HOME/.cargo/env"
  fi
}

install_starship() {
  command -v starship >/dev/null 2>&1 && { echo ">>> starship vorhanden."; return; }
  echo ">>> Installiere starship…"
  pm_update
  if ! pm_install "starship"; then
    curl -fsSL https://starship.rs/install.sh | bash -s -- -y
  fi
}
install_eza() {
  command -v eza >/dev/null 2>&1 && { echo ">>> eza vorhanden."; return; }
  echo ">>> Installiere eza…"
  pm_update
  if ! pm_install "eza"; then
    ensure_rustup
    cargo install eza --locked
    [[ ":$PATH:" == *":$HOME/.cargo/bin:"* ]] || echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
  fi
}

# --- Bare-Repo einrichten ---
if [[ ! -f "$DOTDIR/HEAD" ]]; then
  mkdir -p "$DOTDIR"; git init --bare "$DOTDIR"
fi
git --git-dir="$DOTDIR" remote | grep -q '^origin$' \
  && git --git-dir="$DOTDIR" remote set-url origin "$REPO_URL" \
  || git --git-dir="$DOTDIR" remote add origin "$REPO_URL"

git --git-dir="$DOTDIR" config core.worktree "$WORKTREE"
git --git-dir="$DOTDIR" config status.showUntrackedFiles no
git --git-dir="$DOTDIR" config pull.rebase true
git --git-dir="$DOTDIR" config fetch.prune true
git config --global --add safe.directory "$DOTDIR" || true

echo ">>> Fetch origin…"
git --git-dir="$DOTDIR" --work-tree="$WORKTREE" fetch origin --prune
DEFAULT_REF="$(git --git-dir="$DOTDIR" symbolic-ref --quiet --short refs/remotes/origin/HEAD || true)"
[[ -z "$DEFAULT_REF" ]] && for b in main master; do
  git --git-dir="$DOTDIR" show-ref --verify --quiet "refs/remotes/origin/$b" && DEFAULT_REF="origin/$b" && break
done
[[ -z "$DEFAULT_REF" ]] && { echo "Kein Default-Branch."; exit 1; }
DEFAULT_BRANCH="${DEFAULT_REF#origin/}"

git --git-dir="$DOTDIR" --work-tree="$WORKTREE" checkout -f "$DEFAULT_REF"
git --git-dir="$DOTDIR" --work-tree="$WORKTREE" reset --hard "$DEFAULT_REF"

# --- .bash_ssh anlegen ---
SSH_FILE="$HOME/.bash_ssh"
if [[ -f "$SSH_FILE" ]]; then
  cp "$SSH_FILE" "${SSH_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
  echo ">>> Alte .bash_ssh gesichert."
fi
cat > "$SSH_FILE" <<'EOF'
# ~/.bash_ssh – individuelle SSH-Umgebung
# Hier kannst du SSH-Agents, Keys oder Remote-Aliase definieren.

# Beispiel:
# export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
# alias sshcfg='vim ~/.ssh/config'

# Automatisch SSH-Agent starten (optional)
# eval "$(ssh-agent -s)" > /dev/null 2>&1
EOF
chmod 600 "$SSH_FILE"
echo ">>> .bash_ssh angelegt."

# --- optionale Tools ---
$INSTALL_STARSHIP && install_starship
$INSTALL_EZA && install_eza

echo ">>> Fertig. Teste:"
echo "    config remote -v"
echo "    config status"
[[ "$REPO_URL" =~ ^git@github\.com: ]] && echo ">>> SSH-Test: ssh -T git@github.com"

