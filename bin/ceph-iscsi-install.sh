cd ~/ceph-iscsi

sudo systemctl stop rbd-target-gw
sudo pkill -f '/usr/bin/python3 -u /usr/bin/rbd-target-gw'
sudo systemctl stop rbd-target-api
sudo pkill -f '/usr/bin/python3 /usr/bin/rbd-target-api'

sudo python3 setup.py install

sleep 5
sudo rbd-target-gw &
sleep 5
sudo rbd-target-api &
sleep 5