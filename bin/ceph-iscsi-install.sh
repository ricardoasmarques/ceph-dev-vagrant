cd ~/ceph-iscsi

sudo python3 setup.py install

sudo systemctl reset-failed
sudo systemctl restart rbd-target-gw
sudo systemctl restart rbd-target-api
