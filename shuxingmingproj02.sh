#!/bin/bash

#####U disk,device disk,fdisk
reap -p "please input your name of udisk.As /dev/sdb" name

mulu=/dev/sdb
fdisk -l $mulu
if [ $? eq 0 ];then

dd if=/dev/zero of=${mulu} bs=500 count=1
fdisk -cu /dev/sdb
fdisk $mulu <<EOF
n
p
1


a
1
w
EOF
mkfs.ext4 mulu &> /dev/null
mkdir -p ${mulu}
mount ${mulu'1'} ${mulu}

###config YUM
cat>//etc/yum.repos.d/redhat.repo <<EOF
[server]
name=server
baseurl=http://172.25.254.250/notes/iso/rhel-server-6.3-x86_64-dvd.iso
enable=1
gpgcheck=0
EOF

#######install file system and BASH procedure ,important order,basic service

mkdir -p /dev/shm/usb
yum -y install filesystem bash coreutils passwd shadow-utils openssh-clients rpm yum net-tools bind-utils vim-enhanced findutils lvm2 util-linux-ng --installroot=/dev/shm/usb/
cp -arv /dev/shm/usb/* /mnt/usb/

#####install neihe
cp /boot/vmlinuz-2.6.32-279.el6.x86_64  /mnt/usb/boot/
cp /boot/initramfs-2.6.32-279.el6.x86_64.img  /mnt/usb/boot/
cp -arv /lib/modules/2.6.32-279.el6.x86_64/  /mnt/usb/lib/modules/


#####安装GRUB程序

rpm -ivh ftp://172.25.254.250/notes/project/software/grub-0.97-77.el6.x86_64.rpm --root=/mnt/usb/ --nodeps --force
grub-install --root-directory=${mulu}  --recheck  ${mulu}

ls /mnt/usb/boot/grub/

定义grub.conf
cp /boot/grub/grub.conf /mnt/usb/boot/grub/
#echo "">/mnt/usb/boot/grub/
uuid=$(blkid /dev/sda1 | awk '{print $2}' | sed 's/"//g')
 
cat >/mnt/usb/boot/grub.conf/<<EOF

default=0
timeout=5
splashimage=(hd0,0)/boot/grub/splash.xpm.gz
hiddenmenu
title Red Hat Enterprise Linux (2.6.32-279.el6.x86_64)
        root (hd0,0)
        kernel /boot/vmlinuz ro root=$uuid selinux=0
        initrd /boot/initramfs-2.6.32-279.el6.x86_64.img
EOF

######完善环境变量与配置文件:
cp /etc/skel/.bash* /mnt/usb/root/
chroot /mnt/usb/
exit


cat>/mnt/usb/etc/sysconfig/network <<EOF

NETWORKING=yes
HOSTNAME=usb.hugo.org
EOF

cp /etc/sysconfig/network-scripts/ifcfg-eth0 /mnt/usb/etc/sysconfig/network-scripts/

cat>/mnt/usb/etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
DEVICE=eth0
BOOTPROTO=none
ONBOOT=yes
USERCTL=no
IPADDR=192.168.0.123
NETMASK=255.255.255.0
GATEWAY=192.168.0.254

EOF

cat >${mulu}/etc/fstab<<EOF
${uuid_fs} / ext4 defaults 0 0
sysfs                   /sys                    sysfs   defaults        0 0
proc                    /proc                   proc    defaults        0 0
tmpfs                   /dev/shm                tmpfs   defaults        0 0
devpts                  /dev/pts                devpts  gid=5,mode=620  0 0
EOF

####mima

sed  '/^root/d' ${mulu}/etc/shadow
echo 'root123:$1$LnssQ/$LMaRecErPKEkqFX9B7jCq.:17377:0:99999:7:::' >> ${mulu}/etc/shadow
echo "root password is : 123456"

###同步脏数据
sync
reboot

##xuan选择从U盘启动
