#!/bin/bash
echo -n "Enter Connect-String without 'as sysdba' for SYS account [ENTER] "
read SYSPWD
echo ${SYSPWD}

echo -n "Enter owner schema for CodeGenerator [ENTER] "
read OWNER
echo ${OWNER}

echo -n "Enter default language (Oracle language name) [ENTER] "
read DEFAULT_LANGUAGE
echo ${DEFAULT_LANGUAGE}

NLS_LANG=GERMAN_GERMANY.AL32UTF8
export NLS_LANG
sqlplus /nolog<<EOF
connect ${SYSPWD} as sysdba 
@install_code_generator ${OWNER} ${DEFAULT_LANGUAGE}
pause
EOF

