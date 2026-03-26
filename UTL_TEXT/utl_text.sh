#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage:
  ./utl_text.sh <command> [options]

Commands:
  install           Install UTL_TEXT into the owner schema
  install-client    Grant UTL_TEXT to one client schema
  uninstall         Remove UTL_TEXT from the owner schema
  help              Show this help

Common options:
  --owner <schema>
  --service <service>
  --client <schema>
  --default-language <lang>
  --log-dir <path>

Environment:
  UTL_TEXT_OWNER
  UTL_TEXT_OWNER_PW
  UTL_TEXT_CLIENT
  UTL_TEXT_CLIENT_PW
  UTL_TEXT_SERVICE
  UTL_TEXT_DEFAULT_LANGUAGE
  UTL_TEXT_LOG_DIR

Passwords are intentionally not accepted via CLI. Provide them via environment
variables or enter them interactively.
EOF
}

COMMAND="${1:-help}"

case "${COMMAND}" in
  install)
    shift
    exec "${SCRIPT_DIR}/install_scripts/install.sh" "$@"
    ;;
  install-client)
    shift
    exec "${SCRIPT_DIR}/install_scripts/install_client.sh" "$@"
    ;;
  uninstall)
    shift
    exec "${SCRIPT_DIR}/install_scripts/uninstall.sh" "$@"
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    echo "Unknown command: ${COMMAND}" >&2
    usage >&2
    exit 1
    ;;
esac
