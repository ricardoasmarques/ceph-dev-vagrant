#!/bin/bash


zypper -n install targetcli-fb tcmu-runner python3-configshell \
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

cat > /etc/ceph/iscsi-gateway.cfg <<EOF
# http://docs.ceph.com/docs/master/rbd/iscsi-target-cli/
[config]
cluster_name = ceph
gateway_keyring = ceph.client.admin.keyring
api_secure = false
api_user = admin
api_password = admin
api_port = 5001
trusted_ip_list = 192.168.100.201,192.168.100.202,192.168.100.203,192.168.100.1
# Uncomment this to enable password encryption
# priv_key = keys/private_key
# pub_key = keys/public_key
EOF

sudo cp -r /home/vagrant/keys /etc/ceph

if ! rados lspools | grep -q '^rbd$'; then
  ceph osd pool create rbd 50
  rbd pool init rbd
fi

ceph dashboard iscsi-gateway-add node1 http://admin:admin@192.168.100.201:5001
ceph dashboard iscsi-gateway-add node2 http://admin:admin@192.168.100.202:5001
ceph dashboard iscsi-gateway-add node3 http://admin:admin@192.168.100.203:5001
ceph dashboard iscsi-gateway-list

# Start services
# tcmu-runner
sudo systemctl enable tcmu-runner
sudo systemctl restart tcmu-runner
# ceph-iscsi-gw
sudo systemctl enable rbd-target-gw
sudo systemctl restart rbd-target-gw
# ceph-iscsi-api
sudo systemctl enable rbd-target-api
sudo systemctl restart rbd-target-api

