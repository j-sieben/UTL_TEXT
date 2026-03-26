#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

export NLS_LANG="${NLS_LANG:-GERMAN_GERMANY.AL32UTF8}"

print_common_options() {
  cat <<'EOF'
Options:
  --owner <schema>             Owner schema for UTL_TEXT
  --service <service>          Database service name or PDB
  --client <schema>            Client schema for install-client
  --default-language <lang>    Message language override for install
  --log-dir <path>             Directory for generated log files
  --help                       Show this help

Environment:
  UTL_TEXT_OWNER
  UTL_TEXT_OWNER_PW
  UTL_TEXT_CLIENT
  UTL_TEXT_CLIENT_PW
  UTL_TEXT_SERVICE
  UTL_TEXT_DEFAULT_LANGUAGE
  UTL_TEXT_LOG_DIR
EOF
}

require_sqlplus() {
  if ! command -v sqlplus >/dev/null 2>&1; then
    echo "sqlplus is required but was not found in PATH." >&2
    exit 127
  fi
}

fail_if_non_interactive() {
  local field_name=$1

  if [[ ! -t 0 ]]; then
    echo "Missing required value for ${field_name}. Set it via CLI option or environment variable." >&2
    exit 1
  fi
}

prompt_value() {
  local prompt_text=$1
  local field_name=$2
  local value

  fail_if_non_interactive "${field_name}"
  read -r -p "${prompt_text}" value
  printf '%s' "${value}"
}

prompt_secret() {
  local prompt_text=$1
  local field_name=$2
  local value

  fail_if_non_interactive "${field_name}"
  read -r -s -p "${prompt_text}" value
  echo
  printf '%s' "${value}"
}

resolve_owner_inputs() {
  OWNER="${OWNER:-${UTL_TEXT_OWNER:-}}"
  OWNER_PW="${OWNER_PW:-${UTL_TEXT_OWNER_PW:-}}"
  SERVICE="${SERVICE:-${UTL_TEXT_SERVICE:-}}"

  if [[ -z "${OWNER}" ]]; then
    OWNER="$(prompt_value 'Enter owner schema for UTL_TEXT: ' 'owner schema')"
  fi

  if [[ -z "${OWNER_PW}" ]]; then
    OWNER_PW="$(prompt_secret "Enter password for ${OWNER}: " 'owner password')"
  fi

  if [[ -z "${SERVICE}" ]]; then
    SERVICE="$(prompt_value 'Enter service name for the database or PDB: ' 'database service')"
  fi
}

resolve_client_inputs() {
  CLIENT="${CLIENT:-${UTL_TEXT_CLIENT:-}}"
  CLIENT_PW="${CLIENT_PW:-${UTL_TEXT_CLIENT_PW:-}}"

  if [[ -z "${CLIENT}" ]]; then
    CLIENT="$(prompt_value 'Enter schema to grant access to UTL_TEXT: ' 'client schema')"
  fi

  if [[ -z "${CLIENT_PW}" ]]; then
    CLIENT_PW="$(prompt_secret "Enter password for ${CLIENT}: " 'client password')"
  fi
}

resolve_default_language() {
  DEFAULT_LANGUAGE="${DEFAULT_LANGUAGE:-${UTL_TEXT_DEFAULT_LANGUAGE:-}}"
}

prepare_log_file() {
  local log_name=$1

  LOG_DIR="${LOG_DIR:-${UTL_TEXT_LOG_DIR:-${LIB_DIR}/logs}}"
  mkdir -p "${LOG_DIR}"
  LOG_FILE="${LOG_DIR}/${log_name}"
  : >"${LOG_FILE}"
}

append_log_header() {
  {
    echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S %z')"
    echo "Action: ${ACTION_NAME}"
    echo "Owner: ${OWNER}"
    echo "Service: ${SERVICE}"
    if [[ -n "${CLIENT:-}" ]]; then
      echo "Client: ${CLIENT}"
    fi
    if [[ -n "${DEFAULT_LANGUAGE:-}" ]]; then
      echo "Default language override: ${DEFAULT_LANGUAGE}"
    fi
    echo
  } >>"${LOG_FILE}"
}

run_sqlplus_script() {
  local username=$1
  local password=$2
  local service=$3
  local script_path=$4
  shift 4
  local script_args=("$@")
  local sql_args=""

  for arg in "${script_args[@]}"; do
    sql_args+=" ${arg}"
  done

  {
    echo "Running ${script_path}${sql_args}"
    (
      cd "${LIB_DIR}"
      sqlplus -s /nolog <<SQL
whenever oserror exit failure rollback
whenever sqlerror exit failure rollback
connect ${username}/"${password}"@${service}
define DEFAULT_LANGUAGE_OVERRIDE="${DEFAULT_LANGUAGE:-}"
@${script_path}${sql_args}
exit
SQL
    )
  } >>"${LOG_FILE}" 2>&1
}
