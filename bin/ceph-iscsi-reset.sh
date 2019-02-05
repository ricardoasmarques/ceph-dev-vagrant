cd ~/ceph-iscsi

sudo targetcli clearconfig confirm=True
ceph osd pool delete rbd rbd --yes-i-really-really-mean-it
sleep 3
if ! rados lspools | grep -q '^rbd$'; then
  ceph osd pool create rbd 1 1
  rbd pool init rbd
fi
sudo python3 setup.py install

sudo systemctl reset-failed
sudo systemctl restart rbd-target-gw
sudo systemctl restart rbd-target-api
