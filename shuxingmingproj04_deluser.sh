
wst=/ldap_group.txt
user_ldif=/ldap_user.ldif
group_ldif=/ldap_group.ldif
mig_user=/usr/share/migrationtools/migrate_passwd.pl
mig_group=/usr/share/migrationtools/migrate_group.pl
rootdn="cn=admin,dc=example,dc=org"
rootpw=redhat


for user in $(cat newuser.txt)
#while :
do

        read -p "请输入要del的LDAP User[输入q推测出]:" user
        if [ "$user" = "q" ] ;then
           exit
        fi
#uid_del=$(id $user|)

ldapdelete -x -D "cn=Manager,dc=example,dc=org" -w redhat "uid=$user,ou=People,dc=example,dc=org"
        if [ "$u1" = 1  ] ;then
                echo "del用户$user成功!"
	else echo "del用户$user failed"
        fi
done



