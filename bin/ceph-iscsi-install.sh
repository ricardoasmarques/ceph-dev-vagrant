cd ~/ceph-iscsi

sudo systemctl stop rbd-target-gw
sudo pkill -f 'sudo /usr/bin/rbd-target-gw'
sudo systemctl stop rbd-target-api
sudo pkill -f 'sudo /usr/bin/rbd-target-api'

sudo python setup.py install

sudo /usr/bin/rbd-target-gw &

sudo /usr/bin/rbd-target-api &
