#!/bin/bash
##create user and group
#mkdir /ldapuser
#groupadd -g 10000 ldapuser1
#useradd -u 10000 -g 10000 ldapuser1 -d /ldapuser/ldapuser1
#groupadd -g 10001 ldapuser2
#useradd -u 10001 -g 10001 ldapuser2 -d /ldapuser/ldapuser2
#echo uplooking | passwd --stdin ldapuser1
#echo uplooking | passwd --stdin ldapuser2
#grep ^ldapuser /etc/passwd > /root/passwd.out
#grep ^ldapuser /etc/group > /root/group.out
#cd /usr/share/migrationtools/
#./migrate_base.pl > /root/ldif/base.ldif
#./migrate_passwd.pl /root/passwd.out  > /root/ldif/password.ldif
#./migrate_group.pl /root/group.out > /root/ldif/group.ldif

###10)add user entries to ldap database
###*重要：ldif文件的格式要求非常，非常的严格，一定要注意空白行不能少了。*
#ldapadd -x -D "cn=Manager,dc=example,dc=org" -w redhat -h localhost -f ~/ldif/base.ldif 

#ldapadd -x -D "cn=Manager,dc=example,dc=org" -w redhat -h localhost -f ~/ldif/group.ldif 

#ldapadd -x -D "cn=Manager,dc=example,dc=org" -w redhat -h localhost -f ~/ldif/password.ldif 

###11)
yum -y install httpd
cp /etc/pki/tls/certs/ca.crt /var/www/html/
systemctl start httpd
systemctl enable httpd
yum -y install nfs-utils
cat >/etc/exports<<EOF
/ldapuser       172.25.1.0/24(rw,async)
EOF
systemctl restart rpcbind
systemctl restart nfs

