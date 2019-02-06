#!/bin/bash

zypper -n install nfs-ganesha nfs-ganesha-ceph nfs-ganesha-rgw

HOST=`hostname -s`

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

cat >/tmp/export-1 <<EOF
EXPORT {
  Export_ID=1;
  Path = /;
  Pseudo = /cephfs/;
  Protocols = 3, 4;
  Access_Type = RW;
  Transports = UDP, TCP;
  FSAL {
    Name = CEPH;
    User_ID = "admin";
  }
}
EOF

cat >/tmp/export-2 <<EOF
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

cat >/tmp/conf-${HOST} <<EOF
%url rados://ganesha/export-1
%url rados://ganesha/export-2
EOF

if ! rados lspools | grep -q '^ganesha$'; then
  ceph osd pool create ganesha 1
  ceph osd pool application enable ganesha cephfs
  ceph osd pool application enable ganesha rgw --yes-i-really-mean-it
fi


if ! rados -p ganesha ls | grep -q "^conf-${HOST}$"; then
  rados -p ganesha put conf-${HOST} /tmp/conf-${HOST}
fi

if ! rados -p ganesha ls | grep -q "^export-1$"; then
  rados -p ganesha put export-1 /tmp/export-1
fi

if ! rados -p ganesha ls | grep -q "^export-2$"; then
  rados -p ganesha put export-2 /tmp/export-2
fi

cat >/etc/ganesha/ganesha.conf <<EOF
RADOS_URLS {
  # Path to a ceph.conf file for this cluster.
  Ceph_Conf = /etc/ceph/ceph.conf;

  # RADOS_URLS use their own ceph client too. Authenticated access
  # requires a cephx keyring file.
  UserId = "admin";
  watch_url = "rados://ganesha/conf-${HOST}";
}

%url rados://ganesha/conf-${HOST}

RGW {
  cluster = "ceph";
  name = "${RGW_CLIENT}";
  ceph_conf = "/etc/ceph/ceph.conf";
}
EOF

systemctl start nfs-ganesha

ceph dashboard set-ganesha-clusters-rados-pool-namespace ganesha


