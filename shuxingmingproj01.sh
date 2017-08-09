#!/bin/bash


ipdir="/etc/sysconfig/network-scripts/"
###所有节点关闭selinux与清空防火墙规则


echo "/usr/sbin/setenforce 0" >>  /etc/rc.local
echo "/usr/sbin/iptables -F" >> /etc/rc.local
chmod +x /etc/rc.d/rc.local
source  /etc/rc.local

###DHCP
dhcpfuwu(){
yum install -y dhcp
cat >/etc/dhcp/dhcpd.conf<<EOF
allow booting;
allow bootp;
default-lease-time 600;
max-lease-time 7200;
log-facility local7;
subnet 192.168.0.0 netmask 255.255.255.0 {
  range 192.168.0.50 192.168.0.60;
  option domain-name "pod7.example.com";
  option routers 192.168.0.10;
  option broadcast-address 192.168.0.255;
  default-lease-time 600;
  max-lease-time 7200;
  next-server 192.168.0.16;
  filename "pxelinux.0";
}
EOF
systemctl restart network
systemctl start dhcpd
}



###tftp
tftpfuwu(){
yum install -y xinetd tftp-server syslinux
sed -i  's/disable/enable/' /etc/xinetd.d/tftp
systemctl start xinetd
systemctl enable xinetd


}


###HTTP

httpfuwu() { 
yum -y install httpd
cat >/var/www/html/myks.cfg<<EOF
#version=RHEL7
# System authorization information
auth --enableshadow --passalgo=sha512
# Reboot after installation 
reboot
# Use network installation
url --url="http://192.168.0.16/dvd/"
# Use graphical install
#graphical 
text
# Firewall configuration
firewall --enabled --service=ssh
firstboot --disable 
ignoredisk --only-use=vda
# Keyboard layouts
# old format: keyboard us
# new format:
keyboard --vckeymap=us --xlayouts='us'
# System language 
lang en_US.UTF-8
# Network information
network  --bootproto=dhcp
network  --hostname=localhost.localdomain
#repo --name="Server-ResilientStorage" --baseurl=http://download.eng.bos.redhat.com/rel-eng/latest-RHEL-7/compose/Server/x86_64/os//addons/ResilientStorage
# Root password
rootpw --iscrypted nope 
# SELinux configuration
selinux --disabled
# System services
services --disabled="kdump,rhsmcertd" --enabled="network,sshd,rsyslog,ovirt-guest-agent,chronyd"
# System timezone
timezone Asia/Shanghai --isUtc
# System bootloader configuration
bootloader --append="console=tty0 crashkernel=auto" --location=mbr --timeout=1 --boot-drive=vda 
# Clear the Master Boot Record
zerombr 
# Partition clearing information
clearpart --all --initlabel 
# Disk partitioning information
part / --fstype="xfs" --ondisk=vda --size=6144
%post
echo "redhat" | passwd --stdin root
useradd carol
echo "redhat" | passwd --stdin carol
# workaround anaconda requirements
%end
%packages 
@core
%end
EOF


chown apache. /var/www/html/myks.cfg
mkdir /var/www/html/dvd
mount -o loop /mnt/rhel7.1/x86_64/isos/rhel-server-7.1-x86_64-dvd.iso /var/www/html/dvd/
setenforce 0
systemctl restart httpd


}

###KSCFG

kscfg(){
cat > /root/rhel6-ks.cfg <<EOF
#platform=x86, AMD64, or Intel EM64T
#version=DEVEL
# Install OS instead of upgrade
install
# Keyboard layouts
keyboard 'us'
# Root password
rootpw --iscrypted $1$JFkunSEc$Rd2BA5miAtFILF3sY./Lw1
# System timezone
timezone Asia/Shanghai --isUtc
# Use network installation
url --url="http://$ip_add/rhel6/dvd/"
# System language
lang en_US
# Firewall configuration
firewall --disabled
# System authorization information
auth  --useshadow  --passalgo=sha512
# Use text mode install
text
firstboot --disable
# SELinux configuration
selinux --disabled

# Network information
network  --bootproto=dhcp --device=eth0
# Reboot after installation
reboot
# System bootloader configuration
bootloader --location=mbr
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all --initlabel
# Disk partitioning information
part /boot --fstype="ext4" --size=500
part swap --fstype="swap" --size=2000
part / --fstype="ext4" --grow --size=1
%post
echo "123456" | passwd --stdin root
useradd testuser
echo "123456" | passwd --stdin testuser
%end

%packages
@core

%end

EOF


}



####SYSLINUX

syslinuxfuwu(){
yum -y install syslinux
cp /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/
mkdir /var/lib/tftpboot/pxelinux.cfg
cat>/var/lib/tftpboot/pxelinux.cfg/default<<EOF
default vesamenu.c32
timeout 60
display boot.msg
menu background splash.jpg
menu title Welcome to Global Learning Services Setup!

label local
        menu label Boot from ^local drive
        menu default
        localhost 0xffff

label install
        menu label Install rhel7
        kernel vmlinuz
        append initrd=initrd.img ks=http://192.168.0.16/myks.cfg

EOF

}


dhcpfuwu
tftpfuwu
syslinuxfuwu
kscfg
httpfuwu
