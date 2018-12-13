# Configure ceph
if [ ! -e /home/vagrant/ceph/build/ceph.conf ]; then
  echo "No ceph cluster is running"
  exit 1
fi
mkdir -p /etc/ceph
MON_ADDRS=`cat /home/vagrant/ceph/build/ceph.conf | grep 'mon addr' | sed -e 's/.*mon addr = //'`
MON_ADDRS=`echo $MON_ADDRS | sed 's/ /, /g'`
echo "[client]" > /etc/ceph/ceph.conf
echo "  mon host = $MON_ADDRS" >> /etc/ceph/ceph.conf
echo "  keyring = /etc/ceph/ceph.client.admin.keyring" >> /etc/ceph/ceph.conf
sudo cp /home/vagrant/ceph/build/keyring /etc/ceph/ceph.client.admin.keyring

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
