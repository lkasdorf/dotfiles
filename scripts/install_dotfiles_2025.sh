#!/usr/bin/env bash
set -euo pipefail

# ===== Defaults =====
REPO_URL_DEFAULT_SSH="git@github.com:lkasdorf/dotfiles.git"
REPO_URL_DEFAULT_HTTPS="https://github.com/lkasdorf/dotfiles.git"
REPO_URL="${REPO_URL_DEFAULT_SSH}"

DOTDIR="${HOME}/.dotfiles"
WORKTREE="${HOME}"
ALIAS_NAME="dot"
WRITE_ALIAS_TO_ZSH=true

BACKUP_DIR="${HOME}/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

usage() {
  cat <<EOF
Usage: $0 [--ssh|--https] [--repo URL] [--alias NAME] [--dotdir PATH] [--worktree PATH] [--no-zsh]
  --ssh / --https     Remote-Protokoll (Default: SSH)
  --repo URL          explizite Remote-URL
  --alias NAME        Git-Alias (Default: dot), z.B. --alias=config
  --dotdir PATH       bare-Repo-Pfad (Default: ~/.dotfiles)
  --worktree PATH     Worktree (Default: ~)
  --no-zsh            keinen Alias in ~/.zshrc schreiben
EOF
}

# ===== Args =====
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ssh) REPO_URL="${REPO_URL_DEFAULT_SSH}"; shift ;;
    --https) REPO_URL="${REPO_URL_DEFAULT_HTTPS}"; shift ;;
    --repo) REPO_URL="${2}"; shift 2 ;;
    --alias) ALIAS_NAME="${2}"; shift 2 ;;
    --dotdir) DOTDIR="${2}"; shift 2 ;;
    --worktree) WORKTREE="${2}"; shift 2 ;;
    --no-zsh) WRITE_ALIAS_TO_ZSH=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unbekannter Parameter: $1"; usage; exit 2 ;;
  esac
done

echo ">>> Repo: ${REPO_URL}"
echo ">>> DOTDIR: ${DOTDIR}"
echo ">>> WORKTREE: ${WORKTREE}"
echo ">>> Alias: ${ALIAS_NAME}"

command -v git >/dev/null 2>&1 || { echo "git fehlt."; exit 1; }

# ===== Bare-Repo anlegen/übernehmen =====
if [[ ! -d "${DOTDIR}" ]]; then
  echo ">>> Initialisiere bare-Repo: ${DOTDIR}"
  mkdir -p "${DOTDIR}"
  git --git-dir="${DOTDIR}" --work-tree="${WORKTREE}" init --bare
else
  echo ">>> Bare-Repo existiert bereits: ${DOTDIR}"
fi

# ===== Remote setzen =====
if git --git-dir="${DOTDIR}" remote | grep -q '^origin$'; then
  git --git-dir="${DOTDIR}" remote set-url origin "${REPO_URL}"
else
  git --git-dir="${DOTDIR}" remote add origin "${REPO_URL}"
fi

# ===== Grund-Config =====
git --git-dir="${DOTDIR}" config core.worktree "${WORKTREE}"
git --git-dir="${DOTDIR}" config status.showUntrackedFiles no
git --git-dir="${DOTDIR}" config pull.rebase true
git --git-dir="${DOTDIR}" config fetch.prune true
git config --global --add safe.directory "${DOTDIR}" || true

# ===== Fetch & Default-Branch ermitteln =====
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

# Lokalen Branch sicherstellen
if ! git --git-dir="${DOTDIR}" show-ref --verify --quiet "refs/heads/${DEFAULT_BRANCH}"; then
  ANY_HEAD="$(git --git-dir="${DOTDIR}" for-each-ref --format='%(refname:short)' refs/heads | head -n1 || true)"
  if [[ -n "${ANY_HEAD}" && "${ANY_HEAD}" != "${DEFAULT_BRANCH}" ]]; then
    git --git-dir="${DOTDIR}" branch -M "${ANY_HEAD}" "${DEFAULT_BRANCH}" || true
  else
    git --git-dir="${DOTDIR}" branch "${DEFAULT_BRANCH}" || true
  fi
fi
git --git-dir="${DOTDIR}" --work-tree="${WORKTREE}" branch --set-upstream-to="origin/${DEFAULT_BRANCH}" "${DEFAULT_BRANCH}" || true

# ===== Backup kollidierender Dateien =====
echo ">>> Backup möglicher Konflikte: ${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}"
mapfile -t TRACKED < <(git --git-dir="${DOTDIR}" ls-tree -r --name-only "origin/${DEFAULT_BRANCH}")
for f in "${TRACKED[@]}"; do
  [[ -z "${f}" ]] && continue
  if [[ -e "${WORKTREE}/${f}" && ! -L "${WORKTREE}/${f}" ]]; then
    cp --parents -a "${WORKTREE}/${f}" "${BACKUP_DIR}/" || true
  fi
done

# ===== Checkout =====
git --git-dir="${DOTDIR}" --work-tree="${WORKTREE}" checkout -f "origin/${DEFAULT_BRANCH}"
git --git-dir="${DOTDIR}" --work-tree="${WORKTREE}" reset --hard "origin/${DEFAULT_BRANCH}"

# ===== Alias schreiben =====
write_alias() {
  local rcfile="$1"
  [[ -f "${rcfile}" ]] || return 0
  local line="alias ${ALIAS_NAME}='git --git-dir=${DOTDIR} --work-tree=${WORKTREE}'"
  if grep -Fqx "${line}" "${rcfile}"; then
    echo ">>> Alias bereits in ${rcfile}"
  else
    echo "${line}" >> "${rcfile}"
    echo ">>> Alias zu ${rcfile} hinzugefügt"
  fi
}
write_alias "${HOME}/.bashrc"
[[ "${WRITE_ALIAS_TO_ZSH}" == "true" ]] && write_alias "${HOME}/.zshrc"

echo ">>> Fertig. Neues Terminal öffnen oder 'source ~/.bashrc'."
echo ">>> Checks:"
echo "    - '${ALIAS_NAME} remote -v'"
echo "    - '${ALIAS_NAME} status'"
[[ "${REPO_URL}" =~ ^git@github\.com: ]] && echo ">>> SSH-Test: ssh -T git@github.com"
echo ">>> Backups: ${BACKUP_DIR}"
