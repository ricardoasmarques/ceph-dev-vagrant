cd ~/ceph-iscsi

sudo targetcli clearconfig confirm=True
rados -p rbd rm gateway.conf

sudo python3 setup.py install

sudo systemctl reset-failed
sudo systemctl restart rbd-target-gw
sudo systemctl restart rbd-target-api
