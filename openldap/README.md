# OpenLDAP

See: https://hub.docker.com/r/bitnami/openldap/

Install as (using the docker-compose.yaml file):

    sudo docker-compose up -d
    
## Install with TLS/SSL enabled

First create the necessary certifikates and keys.
See also: https://ubuntu.com/server/docs/service-ldap-with-tls

    $ certtool --generate-privkey --bits 4096 --outfile /etc/ssl/private/mycakey.pem
    $ cat > /etc/ssl/ca.info
    cn = Example Company
    ca
    cert_signing_key
    expiration_days = 3650
    ^D
    $ certtool --generate-self-signed --load-privkey /etc/ssl/private/mycakey.pem --template /etc/ssl/ca.info --outfile /usr/local/share/ca-certificates/mycacert.crt
    $ update-ca-certificates
    $ certtool --generate-privkey --bits 2048 --outfile /etc/ldap/ldap01_slapd_key.pem
    $ cat > /etc/ssl/ldap01.info
    organization = Example Company
    cn = ldap01.example.com
    tls_www_server
    encryption_key
    signing_key
    expiration_days = 365
    ^D
    $ certtool --generate-certificate --load-privkey /etc/ldap/ldap01_slapd_key.pem --load-ca-certificate /etc/ssl/certs/mycacert.pem --load-ca-privkey /etc/ssl/private/mycakey.pem --template /etc/ssl/ldap01.info --outfile /etc/ldap/ldap01_slapd_cert.pem
    $ chgrp openldap /etc/ldap/ldap01_slapd_key.pem
    $ chmod 0640 /etc/ldap/ldap01_slapd_key.pem
    $ cd /etc/ldap
    $ mkdir -p bitnami/certs
    $ cd bitnami/certs
    $ cp /etc/ssl/certs/mycacert.pem openldapCA.crt
    $ cp /etc/ldap/ldap01_slapd_cert.pem openldap.crt
    $ cp /etc/ldap/ldap01_slapd_key.pem openldap.key
    
Then start the container:

    ./mydock run --config openldap-tls.conf


See also: https://kifarunix.com/setup-openldap-server-with-ssl-tls-on-debian-10/


## Working with OpenLDAP

Add the Engineering organisation:

    ldapadd -x -D "cn=admin,dc=example,dc=com" -w admin -h localhost -p 1389 \
            -f openldap/engineering.ldif

Add the groups entry:

    ldapadd -x -D "cn=admin,dc=example,dc=com" -w admin -h localhost -p 1389 \
            -f openldap/groups.ldif

Add some engineers:

    ldapadd -x -D "cn=admin,dc=example,dc=com" -w admin -h localhost -p 1389 \
            -f openldap/engineers.ldif

Add the 'titan' group + one member 

    ldapadd -x -D "cn=admin,dc=example,dc=com" -w admin -h localhost -p 1389 -f openldap/titan.ldif 

Add the 'onyx' group + one member.

    ldapadd -x -D "cn=admin,dc=example,dc=com" -w admin -h localhost -p 1389 -f openldap/onyx.ldif 

Add a new member to the 'titan' group:

    ./add-group-member.sh titan uid=sbrown,ou=engineering,dc=example,dc=com


Search for users
 
    ldapsearch -D cn=admin,dc=example,dc=com -w admin -H "ldap://localhost:1389" -b ou=engineering,dc=example,dc=com uid memberOf
    ldapsearch -D cn=admin,dc=example,dc=com -w admin -H "ldap://localhost:1389" -b ou=engineering,dc=example,dc=com uid=sbrown memberOf


Deleting last member of a group seem to require that the whole group
is deleted since:

    groupobject class 'groupOfNames' requires attribute 'member'

but as long as there as at least one remaining member in the group
a member can be removed as:

    ./delete-group-member.sh titan uid=sbrown,ou=engineering,dc=example,dc=com

## Resources

https://www.openldap.org/doc/admin26/OpenLDAP-Admin-Guide.pdf

https://technicalnotes.wordpress.com/2014/04/19/openldap-setup-with-memberof-overlay/

https://www.adimian.com/blog/how-to-enable-memberof-using-openldap/

https://github.com/bitnami/containers/issues/982#issuecomment-1220354408
