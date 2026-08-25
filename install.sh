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

os() {
  case "$(uname -s)" in
    Darwin) echo "darwin" ;;
    Linux) echo "linux" ;;
    *) echo "unsupported OS: $(uname -s)" >&2; exit 1 ;;
  esac
}

arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "amd64" ;;
    arm64|aarch64) echo "arm64" ;;
    *) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;;
  esac
}

main() {
  local os_name arch_name version url install_dir

  os_name="$(os)"
  arch_name="$(arch)"

  version="${FIREGIT_VERSION:-}"
  if [ -z "$version" ]; then
    version="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
      | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')"
    if [ -z "$version" ]; then
      echo "Could not resolve latest version" >&2
      exit 1
    fi
  fi
  url="https://github.com/${REPO}/releases/download/${version}/${BINARY}_${version#v}_${os_name}_${arch_name}.tar.gz"

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT

  echo "Downloading ${url}..."
  curl -fsSL "$url" -o "${tmp_dir}/firegit.tar.gz"
  tar -xzf "${tmp_dir}/firegit.tar.gz" -C "$tmp_dir"

  install_dir="${INSTALL_DIR:-/usr/local/bin}"
  if [ ! -w "$install_dir" ] 2>/dev/null; then
    install_dir="${HOME}/.local/bin"
    mkdir -p "$install_dir"
  fi

  install -m 0755 "${tmp_dir}/${BINARY}" "${install_dir}/${BINARY}"
  echo "Installed ${BINARY} to ${install_dir}/${BINARY}"

  case ":$PATH:" in
    *":${install_dir}:"*) ;;
    *) echo "Note: ${install_dir} is not on your PATH. Add it, e.g.: export PATH=\"${install_dir}:\$PATH\"" ;;
  esac

  "${install_dir}/${BINARY}" version
}

main "$@"
