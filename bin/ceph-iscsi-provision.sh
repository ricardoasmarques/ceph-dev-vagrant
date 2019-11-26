#!/bin/bash


zypper -n install targetcli-fb tcmu-runner python3-configshell python3-distro\
                  python3-netifaces python3-netaddr python3-rpm \
                  python3-Flask python3-pyOpenSSL tcmu-runner-handler-rbd \
                  open-iscsi libiscsi-utils multipath-tools

# Install ceph-iscsi
if [ -z $1 ]; then
  cd /home/vagrant
  cp -r ceph-iscsi ceph-iscsi-local
  cd ceph-iscsi-local
  sudo python3 setup.py install
  sudo cp /home/vagrant/ceph-iscsi/usr/lib/systemd/system/rbd-target-gw.service /usr/lib/systemd/system
  sudo cp /home/vagrant/ceph-iscsi/usr/lib/systemd/system/rbd-target-api.service /usr/lib/systemd/system
  sudo systemctl daemon-reload
else
  sudo zypper -n install ceph-iscsi
fi

HOST=`hostname -s`

ceph auth get-or-create client.igw.${HOST} \
                        mon 'allow *' \
                        osd 'allow *' \
                        mgr 'allow r' \
                        -o /etc/ceph/ceph.client.igw.${HOST}.keyring

cat >>/etc/ceph/ceph.conf <<EOF

[client.igw.${HOST}]
  keyring = /etc/ceph/ceph.client.igw.${HOST}.keyring

EOF

cat > /etc/ceph/iscsi-gateway.cfg <<EOF
# http://docs.ceph.com/docs/master/rbd/iscsi-target-cli/
[config]
cluster_name = ceph
cluster_client_name = client.igw.${HOST}
api_secure = true
api_user = admin
api_password = admin
api_port = 5001
trusted_ip_list = 192.168.100.201,192.168.100.202,192.168.100.203,192.168.100.1
# Uncomment this to enable password encryption
priv_key = private_key
pub_key = public_key
EOF

sudo cp /home/vagrant/keys/* /etc/ceph/


if ! rados lspools | grep -q '^rbd$'; then
  ceph osd pool create rbd 50
  rbd pool init rbd
fi

# Start services
# tcmu-runner
sudo systemctl enable tcmu-runner
sudo systemctl restart tcmu-runner
# ceph-iscsi
sudo systemctl enable rbd-target-gw
sudo systemctl enable rbd-target-api
sudo systemctl stop rbd-target-gw
sudo systemctl stop rbd-target-api
sudo systemctl start rbd-target-api
sudo systemctl start rbd-target-gw

sleep 5

ceph dashboard set-iscsi-api-ssl-verification false
ceph dashboard iscsi-gateway-add https://admin:admin@192.168.100.201:5001
ceph dashboard iscsi-gateway-add https://admin:admin@192.168.100.202:5001
ceph dashboard iscsi-gateway-add https://admin:admin@192.168.100.203:5001
ceph dashboard iscsi-gateway-list
