#!/usr/bin/env bash
# Sets up the dotfiles as a bare repo in ~/.dotfiles with $HOME as work tree.
# Works on any Linux distribution with git; the optional tools are installed
# through whichever package manager is present, with user-local fallbacks.
set -euo pipefail

REPO_URL_DEFAULT_SSH="git@github.com:lkasdorf/dotfiles.git"
REPO_URL_DEFAULT_HTTPS="https://github.com/lkasdorf/dotfiles.git"
REPO_URL="${REPO_URL_DEFAULT_SSH}"
PUSH_URL=""

DOTDIR="${HOME}/.dotfiles"
WORKTREE="${HOME}"
BACKUP_DIR="${HOME}/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
LOCAL_BIN="${HOME}/.local/bin"

INSTALL_STARSHIP=false
INSTALL_EZA=false
INSTALL_EXTRAS=false

usage() {
  cat <<EOF
Usage: $0 [--ssh|--https] [--repo URL] [--dotdir PATH] [--worktree PATH]
            [--install-starship] [--install-eza] [--with-tools]
  --ssh / --https        Remote-Protokoll (Default: SSH). --https holt über HTTPS
                         und pusht über SSH, braucht also für den Anfang keinen Key.
  --repo URL             Explizite Remote-URL
  --dotdir PATH          Bare-Repo-Verzeichnis (Default: ~/.dotfiles)
  --worktree PATH        Worktree (Default: ~)
  --install-starship     Starship installieren
  --install-eza          eza installieren
  --with-tools           Starship, eza, bat, fzf und zoxide installieren
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ssh) REPO_URL="${REPO_URL_DEFAULT_SSH}"; PUSH_URL=""; shift ;;
    --https) REPO_URL="${REPO_URL_DEFAULT_HTTPS}"; PUSH_URL="${REPO_URL_DEFAULT_SSH}"; shift ;;
    --repo) REPO_URL="${2}"; PUSH_URL=""; shift 2 ;;
    --dotdir) DOTDIR="${2}"; shift 2 ;;
    --worktree) WORKTREE="${2}"; shift 2 ;;
    --install-starship) INSTALL_STARSHIP=true; shift ;;
    --install-eza) INSTALL_EZA=true; shift ;;
    --with-tools) INSTALL_STARSHIP=true; INSTALL_EZA=true; INSTALL_EXTRAS=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unbekannter Parameter: $1"; usage; exit 2 ;;
  esac
done

echo ">>> Repo: ${REPO_URL}"
echo ">>> DOTDIR: ${DOTDIR}"
echo ">>> WORKTREE: ${WORKTREE}"
echo ">>> Extras: starship=${INSTALL_STARSHIP} eza=${INSTALL_EZA} bat/fzf/zoxide=${INSTALL_EXTRAS}"

command -v git >/dev/null 2>&1 || { echo "git fehlt. Erst git über den Paketmanager installieren."; exit 1; }

# --- Package manager (detected by binary, not by distribution name) ---
SUDO=""
if [[ $EUID -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then SUDO="sudo"
  elif command -v doas >/dev/null 2>&1; then SUDO="doas"
  else SUDO="none"
  fi
fi

PM=""
for c in apt-get dnf yum pacman zypper apk xbps-install eopkg brew; do
  command -v "$c" >/dev/null 2>&1 && { PM="$c"; break; }
done
echo ">>> Paketmanager: ${PM:-keiner gefunden}"

PM_UPDATED=false
pm_install() {
  # Installs the given packages, returns non-zero if the manager or a package is missing
  [[ -z "$PM" || "$SUDO" == "none" ]] && return 1
  local s="$SUDO"
  [[ "$PM" == "brew" ]] && s=""
  if ! $PM_UPDATED; then
    case "$PM" in
      apt-get) $s apt-get update -y >/dev/null ;;
      pacman) $s pacman -Sy --noconfirm >/dev/null ;;
      apk) $s apk update >/dev/null ;;
      xbps-install) $s xbps-install -S >/dev/null ;;
    esac || true
    PM_UPDATED=true
  fi
  case "$PM" in
    apt-get) $s env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" ;;
    dnf) $s dnf install -y "$@" ;;
    yum) $s yum install -y "$@" ;;
    pacman) $s pacman -S --noconfirm --needed "$@" ;;
    zypper) $s zypper --non-interactive install "$@" ;;
    apk) $s apk add "$@" ;;
    xbps-install) $s xbps-install -y "$@" ;;
    eopkg) $s eopkg install -y "$@" ;;
    brew) brew install "$@" ;;
    *) return 1 ;;
  esac
}

arch_triple() {
  case "$(uname -m)" in
    x86_64|amd64) echo "x86_64" ;;
    aarch64|arm64) echo "aarch64" ;;
    *) echo "" ;;
  esac
}

ensure_local_bin() {
  mkdir -p "$LOCAL_BIN"
  case ":$PATH:" in *":$LOCAL_BIN:"*) ;; *) export PATH="$LOCAL_BIN:$PATH" ;; esac
}

install_starship() {
  command -v starship >/dev/null 2>&1 && { echo ">>> starship vorhanden."; return 0; }
  echo ">>> Installiere starship…"
  pm_install starship && command -v starship >/dev/null 2>&1 && return 0
  ensure_local_bin
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$LOCAL_BIN" \
    || echo "!!! starship konnte nicht installiert werden."
}

install_eza() {
  command -v eza >/dev/null 2>&1 && { echo ">>> eza vorhanden."; return 0; }
  echo ">>> Installiere eza…"
  pm_install eza && command -v eza >/dev/null 2>&1 && return 0
  ensure_local_bin
  local a; a="$(arch_triple)"
  if [[ -n "$a" ]] && curl -fsSL "https://github.com/eza-community/eza/releases/latest/download/eza_${a}-unknown-linux-gnu.tar.gz" \
       | tar -xz -C "$LOCAL_BIN" 2>/dev/null; then
    chmod +x "$LOCAL_BIN/eza"; return 0
  fi
  if command -v cargo >/dev/null 2>&1; then
    cargo install eza --locked && return 0
  fi
  echo "!!! eza konnte nicht installiert werden. Die ls-Aliase fallen dann auf ls zurück."
}

install_extras() {
  local p
  for p in bat fzf zoxide; do
    case "$p" in
      bat) command -v bat >/dev/null 2>&1 || command -v batcat >/dev/null 2>&1 && continue ;;
      *) command -v "$p" >/dev/null 2>&1 && continue ;;
    esac
    echo ">>> Installiere $p…"
    pm_install "$p" || echo "!!! $p nicht über den Paketmanager verfügbar, übersprungen."
  done
}

link_debian_names() {
  # Debian and Ubuntu ship bat as batcat and fd as fdfind
  ensure_local_bin
  if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
    ln -sf "$(command -v batcat)" "$LOCAL_BIN/bat"
  fi
  if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
    ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"
  fi
}

# --- Bare repo ---
cfg() { git --git-dir="$DOTDIR" --work-tree="$WORKTREE" "$@"; }

if [[ ! -f "$DOTDIR/HEAD" ]]; then
  mkdir -p "$DOTDIR"
  git -c init.defaultBranch=main init --bare -q "$DOTDIR"
fi
if git --git-dir="$DOTDIR" remote | grep -qx origin; then
  git --git-dir="$DOTDIR" remote set-url origin "$REPO_URL"
else
  git --git-dir="$DOTDIR" remote add origin "$REPO_URL"
fi
if [[ -n "$PUSH_URL" ]]; then
  git --git-dir="$DOTDIR" remote set-url --push origin "$PUSH_URL"
fi
git --git-dir="$DOTDIR" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
git --git-dir="$DOTDIR" config status.showUntrackedFiles no
git --git-dir="$DOTDIR" config pull.rebase true
git --git-dir="$DOTDIR" config fetch.prune true
# Older versions of this script set core.worktree on the bare repo, which git warns about
git --git-dir="$DOTDIR" config --unset core.worktree 2>/dev/null || true

echo ">>> Fetch origin…"
cfg fetch origin --prune

DEFAULT_BRANCH="$(git --git-dir="$DOTDIR" ls-remote --symref origin HEAD 2>/dev/null \
  | awk '/^ref:/ { sub("refs/heads/", "", $2); print $2; exit }')"
if [[ -z "$DEFAULT_BRANCH" ]]; then
  for b in main master; do
    git --git-dir="$DOTDIR" show-ref --verify --quiet "refs/remotes/origin/$b" && { DEFAULT_BRANCH="$b"; break; }
  done
fi
[[ -z "$DEFAULT_BRANCH" ]] && { echo "Kein Default-Branch."; exit 1; }
git --git-dir="$DOTDIR" symbolic-ref refs/remotes/origin/HEAD "refs/remotes/origin/$DEFAULT_BRANCH"

# Do not throw away local commits on a re-run
if git --git-dir="$DOTDIR" show-ref --verify --quiet "refs/heads/$DEFAULT_BRANCH"; then
  AHEAD="$(git --git-dir="$DOTDIR" rev-list --count "origin/$DEFAULT_BRANCH..$DEFAULT_BRANCH")"
  if [[ "$AHEAD" -gt 0 ]]; then
    echo "!!! $DEFAULT_BRANCH hat $AHEAD lokale Commits, die nicht auf origin sind. Erst pushen, dann erneut starten."
    exit 1
  fi
fi

# Back up every file the checkout would replace with different content
BACKED_UP=0
while IFS= read -r f; do
  target="$WORKTREE/$f"
  [[ -e "$target" || -L "$target" ]] || continue
  if ! cfg diff --quiet "origin/$DEFAULT_BRANCH" -- "$f" 2>/dev/null; then
    mkdir -p "$BACKUP_DIR/$(dirname "$f")"
    cp -a "$target" "$BACKUP_DIR/$f"
    BACKED_UP=$((BACKED_UP + 1))
  fi
done < <(git --git-dir="$DOTDIR" ls-tree -r --name-only "origin/$DEFAULT_BRANCH")
[[ $BACKED_UP -gt 0 ]] && echo ">>> $BACKED_UP vorhandene Dateien gesichert nach $BACKUP_DIR"

cfg checkout -q -f -B "$DEFAULT_BRANCH" "origin/$DEFAULT_BRANCH"
cfg branch -q --set-upstream-to="origin/$DEFAULT_BRANCH" "$DEFAULT_BRANCH"
echo ">>> Ausgecheckt: $(cfg log --oneline -1)"

# --- ~/.bash_ssh (machine specific, not tracked; only created if missing) ---
SSH_FILE="$HOME/.bash_ssh"
if [[ ! -f "$SSH_FILE" ]]; then
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
fi

# --- optional tools ---
if $INSTALL_STARSHIP; then install_starship; fi
if $INSTALL_EZA; then install_eza; fi
if $INSTALL_EXTRAS; then install_extras; fi
link_debian_names

echo ">>> Fertig. Teste:"
echo "    config remote -v"
echo "    config status"
if [[ "$REPO_URL" =~ ^git@ || "$PUSH_URL" =~ ^git@ ]]; then
  echo ">>> SSH-Test: ssh -T git@github.com"
fi
exit 0
