#!/usr/bin/env bash
# Installs the latest release of firegit (the firegit CLI) into $INSTALL_DIR
# (default /usr/local/bin, falling back to ~/.local/bin if not writable).
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/firegitcli/firegit-releases/main/install.sh | bash
set -euo pipefail

REPO="firegitcli/firegit-releases"
BINARY="firegit"

# Global (not `local` to main) so the EXIT trap below can still see it
# after main() returns - a `local` var goes out of scope by then, which
# under `set -u` fails with "unbound variable" once the trap fires.
tmp_dir=""

# Keep in sync with ascii-art.txt in firegit-cli.
print_ascii_art() {
  if [ -t 1 ]; then
    printf '\033[1;38;2;255;105;0m'
  fi
  cat <<'EOF'

█████ ███ ████  █████  ███  ███ █████   
█░░░░░ █░░█░░░█ █░░░░░█ ░░░  █░░ ░█░░░  
████░░░█░░████░░████░░█░ ██░ █░░░ █░░░░ 
█░░░░  █░░█░░█░ █░░░░ █░░ █░ █░░  █░░   
█░░░░░███░█░░░█░█████░ ███ ░███░  █░░   
 ░░    ░░░ ░░  ░ ░░░░░  ░░░ ░░░░   ░░   
  ░     ░░░ ░   ░ ░░░░░  ░░░  ░░░   ░   
EOF
  if [ -t 1 ]; then
    printf '\033[0m'
  fi
}

ok() {
  if [ -t 1 ]; then
    printf '\033[32m✓\033[0m %s\n' "$1"
  else
    printf '✓ %s\n' "$1"
  fi
}

fail() {
  if [ -t 2 ]; then
    printf '\033[31mError: ✗ %s\033[0m\n' "$1" >&2
  else
    printf 'Error: ✗ %s\n' "$1" >&2
  fi
  exit 1
}

os() {
  case "$(uname -s)" in
    Darwin) echo "darwin" ;;
    Linux) echo "linux" ;;
    *) fail "unsupported OS: $(uname -s)" ;;
  esac
}

arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "amd64" ;;
    arm64|aarch64) echo "arm64" ;;
    *) fail "unsupported architecture: $(uname -m)" ;;
  esac
}

main() {
  local os_name arch_name version url install_dir dest

  echo "Installing firegit..."
  echo

  os_name="$(os)"
  arch_name="$(arch)"

  version="${FIREGIT_VERSION:-}"
  if [ -z "$version" ]; then
    version="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
      | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')" || true
    if [ -z "$version" ]; then
      fail "could not resolve latest version"
    fi
  fi
  ok "Resolved version: ${version} (${os_name}/${arch_name})"

  url="https://github.com/${REPO}/releases/download/${version}/${BINARY}_${version#v}_${os_name}_${arch_name}.tar.gz"

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT

  if ! curl -fsSL "$url" -o "${tmp_dir}/firegit.tar.gz"; then
    fail "download failed. ${version} may not have a build for ${os_name}/${arch_name}."
  fi
  if ! tar -xzf "${tmp_dir}/firegit.tar.gz" -C "$tmp_dir"; then
    fail "could not unpack the ${version} archive for ${os_name}/${arch_name}."
  fi
  ok "Downloaded firegit ${version}"

  install_dir="${INSTALL_DIR:-/usr/local/bin}"
  if [ ! -w "$install_dir" ] 2>/dev/null; then
    install_dir="${HOME}/.local/bin"
    mkdir -p "$install_dir"
  fi

  dest="${install_dir}/${BINARY}"
  install -m 0755 "${tmp_dir}/${BINARY}" "$dest"
  ok "Installed to ${install_dir}"

  print_ascii_art
  echo "firegit"
  echo
  echo "  firegit ${version} installed -> ${dest}"
  echo
  echo "  run 'firegit --help' to get started"
  echo

  case ":$PATH:" in
    *":${install_dir}:"*) ;;
    *) echo "  Note: ${install_dir} is not on your PATH. Add it, e.g.: export PATH=\"${install_dir}:\$PATH\"" ;;
  esac
}

main "$@"
