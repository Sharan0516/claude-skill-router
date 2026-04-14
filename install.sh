#!/usr/bin/env bash
# install.sh - One-command setup for claude-token-optimizer
# Runs: audit (before) -> skill router -> memory router -> audit (after)
# Safe to run multiple times (all steps are idempotent)

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

header()  { echo -e "\n${BOLD}═══════════════════════════════════════════════════════════════${RESET}"; echo -e "${BOLD}  $*${RESET}"; echo -e "${BOLD}═══════════════════════════════════════════════════════════════${RESET}\n"; }
info()    { echo -e "${CYAN}[info]${RESET}  $*"; }
ok()      { echo -e "${GREEN}[ok]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[warn]${RESET}  $*"; }
error()   { echo -e "${RED}[error]${RESET} $*" >&2; }

# ── Preflight ────────────────────────────────────────────────────────────────

if [[ ! -d "${HOME}/.claude" ]]; then
  error "~/.claude/ not found. Install Claude Code first."
  exit 1
fi

if ! command -v python3 &>/dev/null; then
  error "python3 not found. Install Python 3 first."
  exit 1
fi

# ── Step 1: Audit (before) ───────────────────────────────────────────────────

header "Step 1/4: Baseline audit"
python3 "${SCRIPT_DIR}/audit.py" || warn "Audit encountered an issue (non-fatal)"
echo ""

# ── Step 2: Skill Router ────────────────────────────────────────────────────

header "Step 2/4: Skill router (migrate skills to vault)"

if [[ -d "${HOME}/.claude/skills" ]]; then
  bash "${SCRIPT_DIR}/migrate.sh"
else
  info "No ~/.claude/skills/ directory found -- skipping skill migration"
fi

# ── Step 3: Memory Router ───────────────────────────────────────────────────

header "Step 3/4: Memory router (compact memory indexes)"

if [[ -d "${HOME}/.claude/projects" ]]; then
  bash "${SCRIPT_DIR}/memory-router.sh"
else
  info "No ~/.claude/projects/ directory found -- skipping memory compaction"
fi

# ── Step 4: Audit (after) ───────────────────────────────────────────────────

header "Step 4/4: Post-optimization audit"
python3 "${SCRIPT_DIR}/audit.py" || warn "Audit encountered an issue (non-fatal)"

# ── Done ─────────────────────────────────────────────────────────────────────

header "Installation complete"
echo -e "  What was set up:"
echo -e "    ${GREEN}✓${RESET} Skills moved to ~/.claude/skill-vault/ (loaded on-demand)"
echo -e "    ${GREEN}✓${RESET} Skill router installed at ~/.claude/skills/skill-router/"
echo -e "    ${GREEN}✓${RESET} CLAUDE.md updated with skill-router instruction"
echo -e "    ${GREEN}✓${RESET} Memory indexes compacted (no bulk loading)"
echo ""
echo -e "  To undo everything:"
echo -e "    ${CYAN}./restore.sh${RESET}          # restore skills"
echo -e "    ${CYAN}./memory-restore.sh${RESET}   # restore memory"
echo ""
echo -e "  ${BOLD}Restart Claude Code to apply changes.${RESET}"
echo ""
