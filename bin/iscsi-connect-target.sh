#!/bin/bash

sed -i -e 's/InitiatorName=.\+/InitiatorName=iqn.1994-05.com.redhat:rh7-client/g' /etc/iscsi/initiatorname.iscsi

systemctl restart iscsid
systemctl restart multipathd

iscsiadm -m discovery -t st -p 192.168.100.201
iscsiadm -m node -l  # logs in to all gateways

# iscsi -m session -P3  # shows iscsi session information

multipath -ll  # to show multipath infor
