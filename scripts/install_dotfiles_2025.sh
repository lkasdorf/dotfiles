#!/usr/bin/env bash
set -euo pipefail

# =======================
# Dotfiles bare installer
# =======================
REPO_URL_DEFAULT_SSH="git@github.com:lkasdorf/dotfiles.git"
REPO_URL_DEFAULT_HTTPS="https://github.com/lkasdorf/dotfiles.git"
REPO_URL="${REPO_URL_DEFAULT_SSH}"

DOTDIR="${HOME}/.dotfiles"
WORKTREE="${HOME}"
BACKUP_DIR="${HOME}/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

usage() {
  cat <<EOF
Usage: $0 [--ssh|--https] [--repo URL] [--dotdir PATH] [--worktree PATH]
  --ssh / --https     Remote-Protokoll (Default: SSH)
  --repo URL          Explizite Remote-URL
  --dotdir PATH       Bare-Repo-Verzeichnis (Default: ~/.dotfiles)
  --worktree PATH     Worktree (Default: ~)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ssh) REPO_URL="${REPO_URL_DEFAULT_SSH}"; shift ;;
    --https) REPO_URL="${REPO_URL_DEFAULT_HTTPS}"; shift ;;
    --repo) REPO_URL="${2}"; shift 2 ;;
    --dotdir) DOTDIR="${2}"; shift 2 ;;
    --worktree) WORKTREE="${2}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unbekannter Parameter: $1"; usage; exit 2 ;;
  esac
done

echo ">>> Repo: ${REPO_URL}"
echo ">>> DOTDIR: ${DOTDIR}"
echo ">>> WORKTREE: ${WORKTREE}"

command -v git >/dev/null 2>&1 || { echo "git fehlt."; exit 1; }

is_git_dir() {
  [[ -d "$1" ]] && [[ -f "$1/HEAD" ]] && [[ -d "$1/objects" ]]
}

# 1) Bare-Repo initialisieren oder übernehmen
if is_git_dir "${DOTDIR}"; then
  echo ">>> Bare-Repo erkannt: ${DOTDIR}"
else
  echo ">>> Initialisiere bare-Repo: ${DOTDIR}"
  mkdir -p "${DOTDIR}"
  git init --bare "${DOTDIR}"
fi

# 2) Remote setzen
if git --git-dir="${DOTDIR}" remote | grep -q '^origin$'; then
  git --git-dir="${DOTDIR}" remote set-url origin "${REPO_URL}"
else
  git --git-dir="${DOTDIR}" remote add origin "${REPO_URL}"
fi

# 3) Grundkonfiguration
git --git-dir="${DOTDIR}" config core.worktree "${WORKTREE}"
git --git-dir="${DOTDIR}" config status.showUntrackedFiles no
git --git-dir="${DOTDIR}" config pull.rebase true
git --git-dir="${DOTDIR}" config fetch.prune true
git config --global --add safe.directory "${DOTDIR}" || true

# 4) Fetch & Default-Branch erkennen
git --git-dir="${DOTDIR}" --work-tree="${WORKTREE}" fetch origin --prune
DEFAULT_REF="$(git --git-dir="${DOTDIR}" symbolic-ref --quiet --short refs/remotes/origin/HEAD || true)"
if [[ -z "${DEFAULT_REF}" ]]; then
  for b in main master; do
    if git --git-dir="${DOTDIR}" show-ref --verify --quiet "refs/remotes/origin/${b}"; then
      DEFAULT_REF="origin/${b}"
      break
    fi
  done
fi
[[ -z "${DEFAULT_REF}" ]] && { echo "Kein Default-Branch gefunden."; exit 1; }
DEFAULT_BRANCH="${DEFAULT_REF#origin/}"
echo ">>> Default-Branch: ${DEFAULT_BRANCH}"

# 5) Lokalen Branch sicherstellen
if ! git --git-dir="${DOTDIR}" show-ref --verify --quiet "refs/heads/${DEFAULT_BRANCH}"; then
  ANY_HEAD="$(git --git-dir="${DOTDIR}" for-each-ref --format='%(refname:short)' refs/heads | head -n1 || true)"
  if [[ -n "${ANY_HEAD}" && "${ANY_HEAD}" != "${DEFAULT_BRANCH}" ]]; then
    git --git-dir="${DOTDIR}" branch -M "${ANY_HEAD}" "${DEFAULT_BRANCH}" || true
  else
    git --git-dir="${DOTDIR}" branch "${DEFAULT_BRANCH}" || true
  fi
fi
git --git-dir="${DOTDIR}" --work-tree="${WORKTREE}" branch --set-upstream-to="origin/${DEFAULT_BRANCH}" "${DEFAULT_BRANCH}" || true

# 6) Backup kollidierender Dateien
echo ">>> Backup potentieller Konflikte nach: ${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}"
mapfile -t TRACKED < <(git --git-dir="${DOTDIR}" ls-tree -r --name-only "origin/${DEFAULT_BRANCH}")
for f in "${TRACKED[@]}"; do
  [[ -z "${f}" ]] && continue
  if [[ -e "${WORKTREE}/${f}" && ! -L "${WORKTREE}/${f}" ]]; then
    mkdir -p "${BACKUP_DIR}/$(dirname "$f")"
    cp -a "${WORKTREE}/${f}" "${BACKUP_DIR}/${f}" || true
  fi
done

# 7) Checkout
git --git-dir="${DOTDIR}" --work-tree="${WORKTREE}" checkout -f "${DEFAULT_REF}"
git --git-dir="${DOTDIR}" --work-tree="${WORKTREE}" reset --hard "${DEFAULT_REF}"

echo ">>> Fertig!"
echo ">>> Teste dein Setup mit:"
echo "    config remote -v"
echo "    config status"
[[ "${REPO_URL}" =~ ^git@github\.com: ]] && echo ">>> SSH-Test: ssh -T git@github.com"
echo ">>> Backup (falls Konflikte): ${BACKUP_DIR}"

