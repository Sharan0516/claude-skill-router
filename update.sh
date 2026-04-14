#!/usr/bin/env bash
# update.sh - Pull latest changes and re-run installation
# All steps are idempotent, so this is safe to run at any time.

set -euo pipefail

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

header()  { echo -e "\n${BOLD}$*${RESET}"; }
ok()      { echo -e "${GREEN}[ok]${RESET}    $*"; }
info()    { echo -e "${CYAN}[info]${RESET}  $*"; }

header "claude-token-optimizer: update"

# ── Pull latest ──────────────────────────────────────────────────────────────

cd "${SCRIPT_DIR}"

current_hash=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
info "Current version: ${current_hash}"

if git pull --ff-only origin main 2>/dev/null; then
  new_hash=$(git rev-parse --short HEAD)
  if [[ "${current_hash}" == "${new_hash}" ]]; then
    ok "Already up to date (${current_hash})"
  else
    ok "Updated: ${current_hash} -> ${new_hash}"
    echo ""
    echo -e "  ${BOLD}Changes:${RESET}"
    git log --oneline "${current_hash}..${new_hash}" | sed 's/^/    /'
  fi
else
  echo ""
  info "Could not fast-forward. Trying rebase..."
  git pull --rebase origin main
  new_hash=$(git rev-parse --short HEAD)
  ok "Updated: ${current_hash} -> ${new_hash}"
fi

# ── Re-run install ───────────────────────────────────────────────────────────

echo ""
bash "${SCRIPT_DIR}/install.sh"
