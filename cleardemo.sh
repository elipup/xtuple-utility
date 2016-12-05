#!/bin/bash

cd /etc/init
LIS=`ls xtuple-*.conf`

for SVR in ${LIS};
do
SVCNAME="${SVR%.*}"
echo "service $SVCNAME stop"
sudo service $SVCNAME stop

done;
cd -

sudo rm -rf /etc/init/xtuple-*
sudo rm -rf /opt/xtuple/4.9.5/*
sudo rm -rf /etc/xtuple/4.9.5/*
sudo rm -rf /var/www/shop.prodiem.xd*
sudo rm -rf /var/log/node-datasource*.log
sudo rm -rf /etc/nginx/sites-available/*
sudo rm -rf /etc/nginx/sites-enabled/*

rm -rf ~/.config
rm -rf ~/.ssh/config
rm -rf envphp_*
rm -rf tempkey_*
rm -rf choice-*.log
rm -rf install-*.log
rm -rf GITHUB_TOKEN*.log
rm -rf ecomm*.log
#sudo pg_dropcluster 9.3 main
sudo pg_dropcluster 9.3 xtuple --stop
sudo pg_dropcluster 9.3 demo --stop
sudo pg_createcluster 9.3 main
#dropdb -U admin demo495
#dropdb -U admin xd_demo495
#createdb -U admin demo495
#pg_restore -U admin -d demo495 demo495

# ./xtuple-utility.sh
