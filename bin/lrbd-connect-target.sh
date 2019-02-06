#!/bin/bash

sed -i -e 's/InitiatorName=.\+/InitiatorName=iqn.2016-11.org.linux-iscsi.igw.x86:sn.demo-client/g' /etc/iscsi/initiatorname.iscsi

sed -i -e 's/^#\(discovery.sendtargets.auth.authmethod.*\)/\1/g' /etc/iscsi/iscsid.conf

sed -i -e 's/^#\(discovery.sendtargets.auth.username =\).*/\1 eee/g' /etc/iscsi/iscsid.conf
sed -i -e 's/^#\(discovery.sendtargets.auth.password =\).*/\1 fff/g' /etc/iscsi/iscsid.conf

sed -i -e 's/^#\(discovery.sendtargets.auth.username_in =\).*/\1 ggg/g' /etc/iscsi/iscsid.conf
sed -i -e 's/^#\(discovery.sendtargets.auth.password_in =\).*/\1 hhh/g' /etc/iscsi/iscsid.conf


systemctl restart iscsid

sleep 1

iscsiadm -m discovery -t st -p 192.168.100.201

sleep 1

TFILE="/etc/iscsi/nodes/iqn.2016-11.org.linux-iscsi.igw.x86:sn.demo/192.168.100.201,3260,1/default"

sed -i -e 's/^\(node.session.auth.authmethod =\).*/\1 CHAP/g' $TFILE

echo "node.session.auth.username = aaa" >> $TFILE
echo "node.session.auth.password = bbb" >> $TFILE
echo "node.session.auth.username_in = ccc" >> $TFILE
echo "node.session.auth.password_in = ddd" >> $TFILE

iscsiadm -m node -l -p 192.168.100.201

sleep 1

mkfs.ext4 /dev/sda

sleep 1

mount /dev/sda /mnt

sleep 1

i=0; while true; do i=$((i + 1)); echo "$i $(date +%T.%N)" | tee -a /mnt/log.txt; sleep 0.5; done

