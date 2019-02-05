#!/bin/bash

zypper -n install lrbd ceph-iscsi open-iscsi libiscsi-utils multipath-tools \
                  tcmu-runner-handler-rbd tcmu-runner

cat >/tmp/lrbd.conf <<EOF
{
  "pools": [{
    "gateways": [{
      "tpg": [{
        "image": "demo",
        "backstore_emulate_3pc": "1",
        "initiator": "iqn.2016-11.org.linux-iscsi.igw.x86:sn.demo-client",
        "lun": "0"
      }],
      "target": "iqn.2016-11.org.linux-iscsi.igw.x86:sn.demo"
    }],
    "pool": "rbd"
  }],
  "portals": [{
    "name": "portal-node1.ceph.local-1",
    "addresses": ["192.168.100.201"]
  }, {
    "name": "portal-node2.ceph.local-1",
    "addresses": ["192.168.100.202"]
  }],
  "targets": [{
    "hosts": [{
      "host": "node1.ceph.local",
      "portal": "portal-node1.ceph.local-1"
    }, {
      "host": "node2.ceph.local",
      "portal": "portal-node2.ceph.local-1"
    }],
    "target": "iqn.2016-11.org.linux-iscsi.igw.x86:sn.demo"
  }],
  "auth": [{
    "tpg": {
      "userid_mutual": "ccc",
      "mutual": "enable",
      "password": "bbb",
      "userid": "aaa",
      "password_mutual": "ddd"
    },
    "authentication": "tpg+identified",
    "target": "iqn.2016-11.org.linux-iscsi.igw.x86:sn.demo",
    "discovery": {
      "userid_mutual": "ggg",
      "mutual": "enable",
      "userid": "eee",
      "auth": "enable",
      "password_mutual":
      "hhh",
      "password": "fff"
    }
  }]
}
EOF

if ! rados lspools | grep -q '^rbd$'; then
  ceph osd pool create rbd 50
  rbd pool init rbd
fi

if ! rbd ls | grep -q '^demo$'; then
  rbd create demo --size=50G --image-feature layering
fi

HOST=`hostname -s`

ceph auth get-or-create client.igw.${HOST} \
                        mon 'allow *' \
                        osd 'allow *' \
                        mgr 'allow r' \
                        -o /etc/ceph/ceph.client.igw.${HOST}.keyring

cat > /etc/sysconfig/lrbd <<EOF
## Path:        Applications/System
## Description: Ceph iSCSI configuration
## ServiceReload: lrbd
## Type:        string
## Default:
#
# Command line options for lrbd(8) init script.
#
LRBD_OPTIONS="-n client.igw.${HOST}"
EOF

. /etc/sysconfig/lrbd; lrbd -v $LRBD_OPTIONS -f /tmp/lrbd.conf

systemctl enable lrbd
systemctl start lrbd


cat > /etc/ceph/iscsi-gateway.cfg <<EOF
# http://docs.ceph.com/docs/master/rbd/iscsi-target-cli/
[config]
cluster_name = ceph
gateway_keyring = ceph.client.admin.keyring
api_secure = false
api_user = admin
api_password = admin
api_port = 5001
trusted_ip_list = 192.168.100.201,192.168.100.202,192.168.100.203
EOF

systemctl enable tcmu-runner
systemctl restart tcmu-runner

systemctl enable rbd-target-gw
systemctl restart rbd-target-gw

systemctl enable rbd-target-api
systemctl restart rbd-target-api

