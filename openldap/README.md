# Working with OpenLDAP

Add the Engineering organisation:

    ldapadd -x -D "cn=admin,dc=example,dc=com" -w admin -h localhost -p 1389 \
            -f openldap/engineering.ldif

Add the groups entry:

    ldapadd -x -D "cn=admin,dc=example,dc=com" -w admin -h localhost -p 1389 \
            -f openldap/groups.ldif
    
Add the 'titan' group + one member 

    ldapadd -x -D "cn=admin,dc=example,dc=com" -w adminpassword -h localhost -p 1389 -f openldap/titan-member1.ldif 

Add the 'onyx' group + one member.

    ldapadd -x -D "cn=admin,dc=example,dc=com" -w adminpassword -h localhost -p 1389 -f openldap/onyx.ldif 

Add a new member to the 'titan' group:

    ldapmodify -x -D "cn=admin,dc=example,dc=com" -w adminpassword -h localhost -p 1389 -f openldap/titan-member2.ldif 


Search for users
 
    ldapsearch -D cn=admin,dc=example,dc=com -w adminpassword -H "ldap://localhost:1389" -b ou=engineering,dc=example,dc=com uid memberOf
    ldapsearch -D cn=admin,dc=example,dc=com -w adminpassword -H "ldap://localhost:1389" -b ou=engineering,dc=example,dc=com uid=sbrown memberOf


## Resources

https://www.openldap.org/doc/admin26/OpenLDAP-Admin-Guide.pdf

https://technicalnotes.wordpress.com/2014/04/19/openldap-setup-with-memberof-overlay/

https://www.adimian.com/blog/how-to-enable-memberof-using-openldap/

https://github.com/bitnami/containers/issues/982#issuecomment-1220354408
