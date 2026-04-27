#!/usr/bin/env bash
# verify-tap.sh — end-to-end check that the Bronco Homebrew tap installs.
#
# Run this on a Mac (Apple Silicon recommended) to validate that:
#   1. SSH access to the private upstream Bronco repo works.
#   2. ``brew tap`` finds the formula.
#   3. ``brew install`` resolves dependencies and clones at the pinned tag.
#   4. The installed entry-points (``bronco``, ``bronco-web``) are on PATH.
#   5. ``bronco --init`` runs without crashing and emits the platform-aware
#      hints that Tier 8 added.
#
# Run after each formula bump (or on a fresh Mac) to catch tap regressions
# before users do. Exits non-zero on any failure with a tagged log line so
# CI plumbing can grep for the cause.
set -u

red()    { printf '\033[31m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }

fail() { red "FAIL: $*"; exit 1; }
ok()   { green "  ok: $*"; }

[[ "$(uname)" == "Darwin" ]] || fail "this script must run on macOS"
command -v brew >/dev/null || fail "Homebrew not installed (https://brew.sh)"
ok "macOS + Homebrew present"

# 1. SSH access to upstream
yellow "▶ Checking SSH access to The-AI-Cowboys-Projects/Bronco …"
git ls-remote git@github.com:The-AI-Cowboys-Projects/Bronco.git HEAD >/dev/null 2>&1 \
    || fail "no SSH access to upstream Bronco — run 'ssh -T git@github.com' to debug"
ok "SSH access verified"

# 2. Tap
yellow "▶ Tapping The-AI-Cowboys-Projects/bronco …"
brew tap The-AI-Cowboys-Projects/bronco 2>&1 \
    | grep -v -E "^(Already tapped|Tapped)" || true  # idempotent
brew tap | grep -q "^the-ai-cowboys-projects/bronco$" \
    || fail "tap not registered after 'brew tap'"
ok "tap installed"

# 3. Formula present + parses
yellow "▶ Looking up bronco formula …"
brew info bronco >/dev/null 2>&1 \
    || fail "brew info bronco failed — formula not visible from the tap"
ok "formula visible"

# 4. Install (idempotent — reinstall on second run)
yellow "▶ Installing bronco (this clones the upstream repo at v0.3.0) …"
if brew list bronco >/dev/null 2>&1; then
    yellow "    bronco already installed — running 'brew reinstall' to test fresh path"
    brew reinstall bronco \
        || fail "brew reinstall bronco failed"
else
    brew install bronco \
        || fail "brew install bronco failed"
fi
ok "install complete"

# 5. Binaries on PATH
for bin in bronco bronco-web; do
    command -v "$bin" >/dev/null \
        || fail "'$bin' is not on PATH after install"
done
ok "bronco + bronco-web on PATH"

# 6. --init runs and prints platform hints
yellow "▶ Running 'bronco --init' …"
init_output=$(bronco --init 2>&1) \
    || fail "bronco --init exited non-zero"
echo "$init_output" | grep -q "Next steps" \
    || fail "bronco --init did not emit the Tier 8 'Next steps' block"
echo "$init_output" | grep -q -E "PYTORCH_ENABLE_MPS_FALLBACK|brew install ollama" \
    || fail "Apple Silicon hints missing from --init output"
ok "bronco --init emits platform-aware hints"

# 7. Version sanity
installed_version=$(bronco --version 2>/dev/null || echo "")
if [[ -z "$installed_version" ]]; then
    yellow "    (bronco --version not implemented; skipping version check)"
else
    [[ "$installed_version" == *"0.3.0"* ]] \
        || fail "expected v0.3.0, got: $installed_version"
    ok "bronco --version reports 0.3.0"
fi

green "✓ All tap-validation checks passed."
