#!/bin/bash
####1)install software
iptables -F
setenforce 0
yum install openldap-clients migrationtools openldap-servers openldap -y



##2)config start openldap
yum install -y expect
expect <<EOF
spawn slappasswd
expect {
"password:" {send "config\r";exp_continue}
	q {exit}

       }
EOF

###3)get configur of slapd.conf
cat >/etc/openldap/slapd.conf<<EOF
include         /etc/openldap/schema/corba.schema
include         /etc/openldap/schema/core.schema
include         /etc/openldap/schema/cosine.schema
include         /etc/openldap/schema/duaconf.schema
include         /etc/openldap/schema/dyngroup.schema
include         /etc/openldap/schema/inetorgperson.schema
include         /etc/openldap/schema/java.schema
include         /etc/openldap/schema/misc.schema
include         /etc/openldap/schema/nis.schema
include         /etc/openldap/schema/openldap.schema
include         /etc/openldap/schema/pmi.schema
include         /etc/openldap/schema/ppolicy.schema
include         /etc/openldap/schema/collective.schema
allow bind_v2
pidfile         /var/run/openldap/slapd.pid
argsfile        /var/run/openldap/slapd.args
####  Encrypting Connections
TLSCACertificateFile /etc/pki/tls/certs/ca.crt
TLSCertificateFile /etc/pki/tls/certs/slapd.crt
TLSCertificateKeyFile /etc/pki/tls/certs/slapd.key
### Database Config###          
database config
rootdn "cn=admin,cn=config"
rootpw {SSHA}IeopqaxvZY1/I7HavmzRQ8zEp4vwNjmF
access to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth manage by * break
### Enable Monitoring
database monitor
# allow only rootdn to read the monitor
access to * by dn.exact="cn=admin,cn=config" read by * none

EOF

rm -rf /etc/openldap/slapd.d/*

slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d
config file testing succeeded

chown -R ldap:ldap /etc/openldap/slapd.d
chmod -R 000 /etc/openldap/slapd.d
chmod -R u+rwx /etc/openldap/slapd.d

###5)get key about ldap
wget ftp://172.25.254.250/notes/project/UP200/UP200_ldap-master/openldap/other/mkcert.sh
chmod +x mkcert.sh
./mkcert.sh --create-ca-keys 
./mkcert.sh --create-ldap-keys
cd /etc/pki/CA/
cp my-ca.crt /etc/pki/tls/certs/ca.crt
cp ldap_server.key /etc/pki/tls/certs/slapd.key
cp ldap_server.crt  /etc/pki/tls/certs/slapd.crt
cd ~

###6)check if the configuration file is right
cat /etc/openldap/slapd.d/cn\=config.ldif
cat /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{0\}config.ldif

##7)get the database directory and DB_CONFIG file
rm -rf /var/lib/ldap/*
chown ldap.ldap /var/lib/ldap
cp -p /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
chown ldap. /var/lib/ldap/DB_CONFIG
systemctl start  slapd.service

####8)create   database of user


mkdir ~/ldif
vi ~/ldif/bdb.ldif
cd /usr/share/migrationtools
ldapsearch -x -b "cn=config" -D "cn=admin,cn=config" -w config -h localhost dn -LLL | grep -v ^$
ldapadd -x -D "cn=admin,cn=config" -w config -f ~/ldif/bdb.ldif -h localhost
adding new entry "olcDatabase=bdb,cn=config"
ldapsearch -x -b "cn=config" -D "cn=admin,cn=config" -w config -h localhost dn -LLL | grep -v ^$ |tail -1

##9)add user entries

cd /usr/share/migrationtools/
cat >migrate_common.ph<<EOF
# Default DNS domain
$DEFAULT_MAIL_DOMAIN = "example.org";
# Default base
$DEFAULT_BASE = "dc=example,dc=org";
EOF


