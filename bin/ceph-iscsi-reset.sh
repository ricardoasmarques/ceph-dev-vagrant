cd ~/ceph-iscsi

sudo systemctl stop rbd-target-gw
sudo pkill -f '/usr/bin/python3 -u /usr/bin/rbd-target-gw'
sudo systemctl stop rbd-target-api
sudo pkill -f '/usr/bin/python3 /usr/bin/rbd-target-api'

sudo targetcli clearconfig confirm=True
ceph osd pool delete rbd rbd --yes-i-really-really-mean-it
sleep 3
if ! rados lspools | grep -q '^rbd$'; then
  ceph osd pool create rbd 1 1
  rbd pool init rbd
fi
sudo python3 setup.py install

sleep 5
sudo rbd-target-gw &
sleep 5
sudo rbd-target-api &
sleep 5
