#https://guides.wp-bullet.com/automatically-back-wordpress-dropbox-wp-cli-bash-script/

#sudo apt-get update
#sudo apt-get install curl -y

sudo curl "https://raw.githubusercontent.com/andreafabrizi/Dropbox-Uploader/master/dropbox_uploader.sh" -o /usr/bin/dropbox_uploader
sudo chmod 755 /usr/bin/dropbox_uploader
dropbox_uploader

#install wp-cli
sudo wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/bin/wp
sudo chmod 755 /usr/bin/wp

# file with backup settings
vim /dropboxbackup_sitename.sh

#cron
crontab -e
01 00 * * * bash /dropboxbackup_sitename.sh

#grep CRON /var/log/syslog

#!/usr/bin/env bash
# Source: https://guides.wp-bullet.com
# Author: Mike

#site name
SITE=site_name

#define local path for backups
BACKUPPATH=tmp/backups

#path to WordPress installation folders
SITESTORE=apps

#date prefix
DATEFORM=$(date +"%Y-%m-%d")

#Days to retain
DAYSKEEP=7

#calculate days as filename prefix
DAYSKEPT=$(date +"%Y-%m-%d" -d "-$DAYSKEEP days")

#create array of sites based on folder names
#SITELIST=($(ls -d $SITESTORE/* | awk -F '/' '{print $NF}'))

#make sure the backup folder exists
mkdir -p $BACKUPPATH

#check if there are old backups and delete them
EXISTS=$(dropbox_uploader list /$SITE | grep -E $DAYSKEPT.*.tar.gz | awk '{print $3}') 
if [ ! -z $EXISTS ]; then
    dropbox_uploader delete /$SITE/$DAYSKEPT-$SITE.tar.gz /$SITE/
    dropbox_uploader delete /$SITE/$DAYSKEPT-$SITE.sql.gz /$SITE/
fi

echo Backing up $SITE
#enter the WordPress folder
cd $SITESTORE/$SITE/public
if [ ! -e $BACKUPPATH/$SITE ]; then
    mkdir -p $BACKUPPATH/$SITE
fi

#back up the WordPress folder
tar -czf $BACKUPPATH/$SITE/$DATEFORM-$SITE.tar.gz .

#back up the WordPress database
wp db export $BACKUPPATH/$SITE/$DATEFORM-$SITE.sql --allow-root
cat $BACKUPPATH/$SITE/$DATEFORM-$SITE.sql | gzip > $BACKUPPATH/$SITE/$DATEFORM-$SITE.sql.gz
# remove the uncompressed sql file
rm $BACKUPPATH/$SITE/$DATEFORM-$SITE.sql

#upload packages
dropbox_uploader upload $BACKUPPATH/$SITE/$DATEFORM-$SITE.tar.gz /$SITE/
dropbox_uploader upload $BACKUPPATH/$SITE/$DATEFORM-$SITE.sql.gz /$SITE/


#if you want to delete all local backups
rm -rf $BACKUPPATH/*

#delete old backups locally over DAYSKEEP days old
find $BACKUPPATH -type d -mtime +$DAYSKEEP -exec rm -rf {} \;

#Fix permissions for standard Debian and Ubuntu installations
#sudo chown -R www-data:www-data $SITESTORE
#sudo find $SITESTORE -type f -exec chmod 777 {} +
#sudo find $SITESTORE -type d -exec chmod 777 {} +
