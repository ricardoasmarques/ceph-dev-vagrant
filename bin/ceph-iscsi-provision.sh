#!/bin/bash

# Install targetcli
cd /home/vagrant
git clone https://github.com/open-iscsi/targetcli-fb.git
cd targetcli-fb
sudo python setup.py install

# Install configshell
cd /home/vagrant
git clone https://github.com/open-iscsi/configshell-fb.git
cd configshell-fb
sudo python setup.py install

#Install python-rtslib
cd /home/vagrant
git clone https://github.com/open-iscsi/rtslib-fb.git
cd rtslib-fb
sudo python setup.py install

# Install tcmu-runner
cd /home/vagrant
git clone https://github.com/open-iscsi/tcmu-runner.git
cd tcmu-runner
./extra/install_dep.sh
cmake -Dwith-glfs=false -Dwith-qcow=false -DSUPPORT_SYSTEMD=ON -DCMAKE_INSTALL_PREFIX=/usr .
make
sudo make install
sudo cp org.kernel.TCMUService1.service /usr/share/dbus-1/system-services
sudo cp tcmu-runner.service /lib/systemd/system

# Install ceph-iscsi
cd /home/vagrant
cd ceph-iscsi
sudo python setup.py install
sudo cp /home/vagrant/ceph-iscsi/usr/lib/systemd/system/rbd-target-gw.service /usr/lib/systemd/system
sudo cp /home/vagrant/ceph-iscsi/usr/lib/systemd/system/rbd-target-api.service /usr/lib/systemd/system
sudo yum -y install python-netifaces python-flask python-netaddr python-cryptography

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
  ceph osd pool create rbd 1 1
  rbd pool init rbd
fi

# Start services
sudo systemctl daemon-reload
# tcmu-runner
sudo systemctl enable tcmu-runner
sudo systemctl restart tcmu-runner
# ceph-iscsi-config
sudo systemctl enable rbd-target-gw
sudo systemctl restart rbd-target-gw
# ceph-iscsi-cli
sudo systemctl enable rbd-target-api
sudo systemctl restart rbd-target-api

