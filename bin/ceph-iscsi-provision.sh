#!/bin/bash


zypper -n install targetcli-fb tcmu-runner python3-configshell \
                  python3-netifaces python3-netaddr python3-rpm \
                  python3-Flask python3-pyOpenSSL tcmu-runner-handler-rbd

# # Install ceph-iscsi
cd /home/vagrant
cp -r ceph-iscsi ceph-iscsi-local
cd ceph-iscsi-local
sudo python3 setup.py install
sudo cp /home/vagrant/ceph-iscsi/usr/lib/systemd/system/rbd-target-gw.service /usr/lib/systemd/system
sudo cp /home/vagrant/ceph-iscsi/usr/lib/systemd/system/rbd-target-api.service /usr/lib/systemd/system


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

if ! rados lspools | grep -q '^rbd$'; then
  ceph osd pool create rbd 50
  rbd pool init rbd
fi

# Start services
# sudo systemctl daemon-reload
# tcmu-runner
sudo systemctl enable tcmu-runner
sudo systemctl restart tcmu-runner
# ceph-iscsi-config
#sudo systemctl enable rbd-target-gw
#sudo systemctl restart rbd-target-gw
# ceph-iscsi-cli
#sudo systemctl enable rbd-target-api
#sudo systemctl restart rbd-target-api

sleep 5
rbd-target-gw &
sleep 5
rbd-target-api &
sleep 5

