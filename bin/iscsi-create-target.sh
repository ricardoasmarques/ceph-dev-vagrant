#!/bin/bash

gwcli /iscsi-targets create iqn.2003-01.com.redhat.iscsi-gw:iscsi-igw
gwcli /iscsi-targets/iqn.2003-01.com.redhat.iscsi-gw:iscsi-igw/gateways create node1 192.168.100.201 skipchecks=true
gwcli /iscsi-targets/iqn.2003-01.com.redhat.iscsi-gw:iscsi-igw/gateways create node2 192.168.100.202 skipchecks=true
gwcli /disks create pool=rbd image=disk_1 size=90G
gwcli /iscsi-targets/iqn.2003-01.com.redhat.iscsi-gw:iscsi-igw/hosts create iqn.1994-05.com.redhat:rh7-client
gwcli /iscsi-targets/iqn.2003-01.com.redhat.iscsi-gw:iscsi-igw/hosts/iqn.1994-05.com.redhat:rh7-client disk add rbd/disk_1
gwcli /iscsi-targets/iqn.2003-01.com.redhat.iscsi-gw:iscsi-igw/hosts auth nochap

gwcli ls
