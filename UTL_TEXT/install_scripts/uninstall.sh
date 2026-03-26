#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=install_common.sh
source "${SCRIPT_DIR}/install_common.sh"

OWNER=""
OWNER_PW=""
SERVICE=""
LOG_DIR=""
DEFAULT_LANGUAGE=""
ACTION_NAME="uninstall"

usage() {
  cat <<'EOF'
Usage:
  ./install_scripts/uninstall.sh [--owner <schema>] [--service <service>] [--log-dir <path>]

Removes UTL_TEXT and its unit-test objects from the owner schema. Missing values
are read from environment variables first and then prompted interactively.
EOF
  print_common_options
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner)
      OWNER=${2:?Missing value for --owner}
      shift 2
      ;;
    --service)
      SERVICE=${2:?Missing value for --service}
      shift 2
      ;;
    --log-dir)
      LOG_DIR=${2:?Missing value for --log-dir}
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

require_sqlplus
resolve_owner_inputs
prepare_log_file "Uninstall_UTL_TEXT.log"
append_log_header
run_sqlplus_script "${OWNER}" "${OWNER_PW}" "${SERVICE}" "install_scripts/uninstall.sql"
run_sqlplus_script "${OWNER}" "${OWNER_PW}" "${SERVICE}" "install_scripts/uninstall_unit_test.sql"

echo "UTL_TEXT uninstall finished. Log: ${LOG_FILE}"
