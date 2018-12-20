#!/bin/bash

yum -y install https://download.ceph.com/nfs-ganesha/rpm-V2.7-stable/mimic/x86_64/libntirpc-1.7.1-0.1.el7.x86_64.rpm
yum -y install https://download.ceph.com/nfs-ganesha/rpm-V2.7-stable/mimic/x86_64/nfs-ganesha-2.7.1-0.1.el7.x86_64.rpm
yum -y install https://download.ceph.com/nfs-ganesha/rpm-V2.7-stable/mimic/x86_64/nfs-ganesha-ceph-2.7.1-0.1.el7.x86_64.rpm
yum -y install https://download.ceph.com/nfs-ganesha/rpm-V2.7-stable/mimic/x86_64/nfs-ganesha-rgw-2.7.1-0.1.el7.x86_64.rpm

RGW_AK=`radosgw-admin user info --uid=testid | jq .keys[0].access_key`
RGW_SK=`radosgw-admin user info --uid=testid | jq .keys[0].secret_key`


RGW_CLIENT=client.rgw.`hostname -s`
ceph auth get-or-create client.rgw.`hostname -s` \
                        mon 'allow rw' \
                        osd 'allow rwx' \
                        mds 'allow rw' \
                        mgr 'allow rw' \
                        -o /etc/ceph/ceph.${RGW_CLIENT}.keyring

cat >>/etc/ceph/ceph.conf <<EOF

[${RGW_CLIENT}]
  keyring = /etc/ceph/ceph.${RGW_CLIENT}.keyring

EOF

cat >/etc/ganesha/my.conf <<EOF
EXPORT {
  Export_ID=1;
  Path = /;
  Pseudo = /cephfs/;
  Protocols = 3, 4;
  Access_Type = RW;
  Transports = UDP, TCP;
  FSAL {
    Name = CEPH;
    User_ID = "fs";
  }
}

EXPORT {
  Export_ID=2;
  Path = "/";
  Pseudo = "/rgw/";
  Access_Type = RW;
  Protocols = 3, 4;
  Transports = UDP, TCP;
  FSAL {
    Name = RGW;
    User_Id="testid";
    Access_Key_Id=${RGW_AK};
    Secret_Access_Key=${RGW_SK};
  }
}
EOF

if ! rados lspools | grep -q '^ganesha$'; then
  ceph osd pool create ganesha 1 1
fi

HOST=`hostname -s`

if ! rados -p ganesha ls | grep -q "^ganesha.${HOST}conf$"; then
  rados -p ganesha put ganesha.${HOST}.conf /etc/ganesha/my.conf
fi

cat >/etc/ganesha/ganesha.conf <<EOF
RADOS_URLS {
  # Path to a ceph.conf file for this cluster.
  Ceph_Conf = /etc/ceph/ceph.conf;

  # RADOS_URLS use their own ceph client too. Authenticated access
  # requires a cephx keyring file.
  UserId = "admin";
}

%url rados://ganesha/ganesha.${HOST}.conf

RGW {
  cluster = "ceph";
  name = "${RGW_CLIENT}";
  ceph_conf = "/etc/ceph/ceph.conf";
}
EOF

# systemctl start nfs-ganesha

