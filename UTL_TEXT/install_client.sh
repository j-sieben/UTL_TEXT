#!/bin/bash
echo -n "Enter owner schema for UTL_TEXT [ENTER] "
read OWNER
echo ${OWNER}

echo -n "Enter password for ${OWNER} [ENTER] "
read -s PWD

echo -n "Enter service name for the database or PDB [ENTER] "
read SERVICE
echo ${SERVICE}

NLS_LANG=GERMAN_GERMANY.AL32UTF8
export NLS_LANG

echo -n "Enter schema to grant access to UTL_TEXT [ENTER] "
read REMOTE_OWNER
echo ${REMOTE_OWNER}

echo -n "Enter password for ${REMOTE_OWNER} [ENTER] "
read -s REMOTE_PWD

sqlplus ${REMOTE_OWNER}/${REMOTE_PWD}@${SERVICE} @tools/check_client_user.sql ${OWNER} ${REMOTE_OWNER}

sqlplus ${OWNER}/"${PWD}"@${SERVICE} @install_scripts/grant_client_access.sql ${OWNER} ${REMOTE_OWNER}

sqlplus ${REMOTE_OWNER}/"${REMOTE_PWD}"@${SERVICE} @install_scripts/create_client_synonyms.sql ${OWNER} ${REMOTE_OWNER}
