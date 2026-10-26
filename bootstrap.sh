#!/bin/bash
# Public bootstrap for bgushurst/dev-setup (private). No secrets, no inventory here.
# Run:  bash -c "$(curl -fsSL https://raw.githubusercontent.com/bgushurst/dotfiles/main/bootstrap.sh)"
# Installs gh, logs in to GitHub, clones dev-setup, asks which host this is, runs that host's setup.
# Safe to re-run.
set -u

# GitHub Codespaces auto-runs bootstrap.sh from a "dotfiles" repo; this isn't for that.
[ "${CODESPACES:-}" = "true" ] && { echo "Codespace: skipping dev-setup bootstrap."; exit 0; }

REPO="bgushurst/dev-setup"
DIR="${DEV_SETUP_DIR:-$HOME/dev-setup}"
say() { printf '\n== %s\n' "$*"; }
die() { printf '\nERROR: %s\n' "$*" >&2; exit 1; }
ask() { local a; read -r -p "$1" a </dev/tty; printf '%s' "$a"; }

OS=$(uname -s)
say "Package manager and gh ($OS)"
case "$OS" in
  Darwin)
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/.local/bin:$PATH"
    if ! command -v brew >/dev/null; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/tty \
        || die "Homebrew install failed"
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    command -v gh >/dev/null || brew install gh || die "brew install gh failed"
    ;;
  Linux)
    if ! command -v gh >/dev/null; then
      command -v apt-get >/dev/null || die "Install gh by hand (https://cli.github.com), then re-run"
      sudo mkdir -p -m 755 /etc/apt/keyrings
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
      sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
      sudo apt-get update -qq && sudo apt-get install -y -qq gh git || die "apt install gh failed"
    fi
    ;;
  *) die "Unsupported OS: $OS" ;;
esac
gh --version | head -1

say "GitHub login"
if ! gh auth status >/dev/null 2>&1; then
  gh auth login --hostname github.com --git-protocol https --web \
    --scopes repo,read:packages,workflow </dev/tty || die "gh auth login failed"
fi
gh auth setup-git
echo "Logged in as $(gh api user -q .login)"

say "dev-setup checkout ($DIR)"
if [ -d "$DIR/.git" ]; then
  git -C "$DIR" pull --ff-only || echo "Pull failed; continuing with the existing checkout."
else
  gh repo clone "$REPO" "$DIR" || die "Clone failed (does this GitHub account have access to $REPO?)"
fi

say "Which host is this?"
HOSTS=$(sed -n 's/^  \([a-z0-9-]*\):.*/\1/p' "$DIR/hosts.yaml")
echo "$HOSTS" | sed 's/^/  /'
HOST="${DEV_SETUP_HOST:-}"
[ -n "$HOST" ] || HOST=$(ask "Host name: ")
echo "$HOSTS" | grep -qx "$HOST" || die "'$HOST' is not in hosts.yaml"
mkdir -p "$HOME/.config/dev-setup" && printf '%s\n' "$HOST" > "$HOME/.config/dev-setup/host"

SETUP="$DIR/scripts/$HOST-setup.sh"
if [ -x "$SETUP" ]; then
  say "Running $SETUP"
  exec "$SETUP" </dev/tty
else
  echo "No setup script for '$HOST' yet ($SETUP). Checkout is ready."
fi
