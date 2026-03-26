#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=install_common.sh
source "${SCRIPT_DIR}/install_common.sh"

OWNER=""
OWNER_PW=""
SERVICE=""
CLIENT=""
CLIENT_PW=""
LOG_DIR=""
DEFAULT_LANGUAGE=""
ACTION_NAME="install-client"

usage() {
  cat <<'EOF'
Usage:
  ./install_scripts/install_client.sh [--owner <schema>] [--service <service>] [--client <schema>] [--log-dir <path>]

Grants UTL_TEXT to a single client schema and creates the client synonyms. Missing
values are read from environment variables first and then prompted interactively.
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
    --client)
      CLIENT=${2:?Missing value for --client}
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
resolve_client_inputs
prepare_log_file "Install_UTL_TEXT_client_${CLIENT}.log"
append_log_header
run_sqlplus_script "${CLIENT}" "${CLIENT_PW}" "${SERVICE}" "tools/check_client_user.sql" "${OWNER}" "${CLIENT}"
run_sqlplus_script "${OWNER}" "${OWNER_PW}" "${SERVICE}" "install_scripts/grant_client_access.sql" "${OWNER}" "${CLIENT}"
run_sqlplus_script "${CLIENT}" "${CLIENT_PW}" "${SERVICE}" "install_scripts/create_client_synonyms.sql" "${OWNER}" "${CLIENT}"

echo "UTL_TEXT client installation finished. Log: ${LOG_FILE}"
