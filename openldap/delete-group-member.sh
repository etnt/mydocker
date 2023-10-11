#!/usr/bin/env bash

group=$1
member=$2

infile="delete-group-member.ldif.template"
outfile="delete-group-member.ldif"

cat ${infile} | sed -e "s/GROUP/${group}/" -e "s/MEMBER/${member}/" > ${outfile}

cat ${outfile}

echo ""
echo "--- Press RETURN to continue, abort with C-c ---"
read

ldapmodify -x -D "cn=admin,dc=example,dc=com" -w admin -h localhost -p 1389 -f ${outfile}
