cd ~/ceph-iscsi

sudo systemctl stop rbd-target-gw
sudo pkill -f 'sudo /usr/bin/rbd-target-gw'
sudo systemctl stop rbd-target-api
sudo pkill -f 'sudo /usr/bin/rbd-target-api'

sudo targetcli clearconfig confirm=True
ceph osd pool delete rbd rbd --yes-i-really-really-mean-it
sleep 3
if ! rados lspools | grep -q '^rbd$'; then
  ceph osd pool create rbd 1 1
fi
sudo python setup.py install

sudo /usr/bin/rbd-target-gw &

sudo /usr/bin/rbd-target-api &
