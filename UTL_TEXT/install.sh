#!/bin/bash
echo -n "Enter owner schema for UTL_TEXT [ENTER] "
read OWNER

echo -n "Enter password for ${OWNER} [ENTER] "
read -s PWD

echo -n "Enter service name for the database or PDB [ENTER] "
read SERVICE

NLS_LANG=GERMAN_GERMANY.AL32UTF8
export NLS_LANG

sqlplus ${OWNER}/"${PWD}"@${SERVICE} @install_scripts/install.sql
