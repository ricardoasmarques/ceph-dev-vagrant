cd ~/ceph-iscsi

sudo targetcli clearconfig confirm=True
rados -p rbd rm gateway.conf

sudo python3 setup.py install

sudo systemctl reset-failed
sudo systemctl stop rbd-target-gw
sudo systemctl stop rbd-target-api
sudo systemctl start rbd-target-api
sudo systemctl start rbd-target-gw
