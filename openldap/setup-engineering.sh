#!/usr/bin/env bash

echo "Add the Engineering organisation."
ldapadd -x -D "cn=admin,dc=example,dc=com" -w admin -h localhost -p 1389 \
        -f ldifs/engineering.ldif
echo "Result: $?"

echo "Add the groups entry."
ldapadd -x -D "cn=admin,dc=example,dc=com" -w admin -h localhost -p 1389 \
        -f ldifs/groups.ldif
echo "Result: $?"

echo "Add some engineers."
ldapadd -x -D "cn=admin,dc=example,dc=com" -w admin -h localhost -p 1389 \
        -f ldifs/engineers.ldif
echo "Result: $?"

echo -n "Add the 'titan' group + one member."
ldapadd -x -D "cn=admin,dc=example,dc=com" -w admin -h localhost -p 1389 -f ldifs/titan.ldif
echo "Result: $?"

echo -n "Add the 'onyx' group + one member."
ldapadd -x -D "cn=admin,dc=example,dc=com" -w admin -h localhost -p 1389 -f ldifs/onyx.ldif
echo "Result: $?"
