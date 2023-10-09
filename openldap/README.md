# Working with OpenLDAP

https://technicalnotes.wordpress.com/2014/04/19/openldap-setup-with-memberof-overlay/

https://www.adimian.com/blog/how-to-enable-memberof-using-openldap/

Add the Engineering organisation:

    ldapadd -x -D "cn=admin,dc=example,dc=org" -w admin -h localhost -p 1389 \
            -f openldap/engineering.ldif

Add the groups entry:

    ldapadd -x -D "cn=admin,dc=example,dc=org" -w admin -h localhost -p 1389 \
            -f openldap/groups.ldif
    
Add some engineers to Engineering: 
  
    ldapadd -x -D "cn=admin,dc=example,dc=org" -w admin -h localhost -p 1389 \
            -f openldap/engineers.ldif
    
Perform a search:

    ldapsearch -x -b "dc=example,dc=org" -h localhost -p 1389 \
               -D "cn=admin,dc=example,dc=org" -w admin
    
    # Search for a particular engineer
    ldapsearch -x -b "dc=example,dc=org" -h localhost -p 1389 \
               -D "cn=admin,dc=example,dc=org" -w admin "uid=sbrown"
