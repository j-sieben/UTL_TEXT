#!/bin/bash
echo -n "Enter owner schema for UTL_TEXT [ENTER] "
read OWNER
echo ${OWNER}

echo -n "Enter password for ${OWNER} [ENTER] "
read PWD

echo -n "Enter service name for the database or PDB [ENTER] "
read SERVICE
echo ${SERVICE}

NLS_LANG=GERMAN_GERMANY.AL32UTF8
export NLS_LANG

echo -n "Enter schema to grant access to UTL_TEXT [ENTER] "
read REMOTE_OWNER
echo ${REMOTE_OWNER}

echo -n "Enter password for ${REMOTE_OWNER} [ENTER] "
read REMOTE_PWD

echo @tools/check_client_user.sql ${REMOTE_OWNER} | sqlplus ${REMOTE_OWNER}/${REMOTE_PWD}@${SERVICE}

echo @install_scripts/grant_client_access.sql ${REMOTE_OWNER} | sqlplus ${OWNER}/${PWD}@${SERVICE}

echo @install_scripts/create_client_synonyms.sql | sqlplus ${REMOTE_OWNER}/${REMOTE_PWD}@${SERVICE}

pause
EOF

