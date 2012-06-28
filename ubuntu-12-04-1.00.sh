#!/bin/bash

clear

## set install log path to home dir
INSTALLLOG=~/zpx_install.log

echo ""
echo "==================================================="
echo "= Starting Auto Installer for ZPX on Ubuntu 12.04 ="
echo "==================================================="
echo "=-------------------------------------------------="
echo "=       By Xengulai (xengulai@xengulai.com)       ="
echo "=-------------------------------------------------="
echo "==================================================="
echo ""


## disable/remove AppArmor
[ -f /etc/init.d/apparmor ]
        if [ $? = "0" ]; then

        echo ""
        echo -n "Stopping and Removing AppArmor: "

        /etc/init.d/apparmor stop &> /dev/null
        update-rc.d -f apparmor remove &> /dev/null
        apt-get -y remove apparmor &> /dev/null
        mv /etc/init.d/apparmor /etc/init.d/apparmpr.removed &> /dev/null

        echo "Done."
        echo ""
        echo "REBOOT THE SERVER AND RUN THE SCRIPT AGAIN"
        echo ""
        echo ""
        exit
        fi


## collect variables for use in script
echo "Variable collection:"

echo -n "Enter Server Public IP Address: "
read SERVER_IP
echo "Enter server name:"
echo "(this should be the reverse lookup of $SERVER_IP)"
echo -n "(ex. zeus.zpanelcp.com): "
read SERVER_NAME
echo -n "Enter FQDN for ZPX (ex. panel.zpanelcp.com): "
read SERVER_CP_NAME
echo -n "Enter MySQL root password: "
read MYSQL_PASS


## pipe output to the install log
exec &>$INSTALLLOG



echo -ne "\nUpdating Aptitude Repos: " >/dev/tty

apt-get update 
apt-get -y install git unzip debconf-utils 

echo "Done." >/dev/tty



echo -n "Creating initial folder structure: " >/dev/tty

mkdir /etc/zpanel
mkdir /etc/zpanel/configs
mkdir /etc/zpanel/panel
mkdir /etc/zpanel/docs
mkdir /var/zpanel
mkdir /var/zpanel/hostdata
mkdir /var/zpanel/hostdata/zadmin
mkdir /var/zpanel/hostdata/zadmin/public_html
mkdir /var/zpanel/logs
mkdir /var/zpanel/backups
mkdir /var/zpanel/temp
## why are we setting to 777 ???
chmod -R 777 /etc/zpanel/
chmod -R 777 /var/zpanel/

echo "Done." >/dev/tty



echo -n "Downloading / Extracting ZPX From github to Temp Directory at /opt/zpanel: " >/dev/tty

mkdir -p /opt/zpanel/

cd /opt/zpanel/

git clone https://github.com/bobsta63/zpanelx.git
cd zpanelx/
git checkout 10.0.0
mkdir ../zpanelexport/
git checkout-index -a -f --prefix=../zpanelexport/
cd ../zpanelexport/

echo "Done." >/dev/tty



echo -n "Copying ZpanelX files to /etc/zpanel: " >/dev/tty

cp -fr * /etc/zpanel/panel
## why are we setting to 777 ???
chmod -R 777 /etc/zpanel/
chmod -R 777 /var/zpanel/
chmod 644 /etc/zpanel/panel/etc/apps/phpmyadmin/config.inc.php
cp -fr /etc/zpanel/panel/etc/build/config_packs/ubuntu_11_10/* /etc/zpanel/configs/

echo "Done." >/dev/tty



echo -n "Registering 'zppy' client: " >/dev/tty

ln -sf /etc/zpanel/panel/bin/zppy /usr/bin/zppy 
chmod +x /usr/bin/zppy 
ln -sf /etc/zpanel/panel/bin/setso /usr/bin/setso 
chmod +x /usr/bin/setso 

echo "Done." >/dev/tty



echo -n "Installing main packages: " >/dev/tty


## preload mysql variables to suppress prompts
echo mysql-server-5.1 mysql-server/root_password password $MYSQL_PASS | debconf-set-selections
echo mysql-server-5.1 mysql-server/root_password_again password $MYSQL_PASS | debconf-set-selections
apt-get -y install mysql-server mysql-server apache2 libapache2-mod-php5 libapache2-mod-bw php5-common php5-suhosin php5-cli php5-mysql php5-gd php5-mcrypt php5-curl php-pear php5-imap php5-xmlrpc php5-xsl db4.7-util zip webalizer build-essential 

echo "Done." >/dev/tty



echo -n "Setting Zpanel MySQL access: " >/dev/tty

cp /opt/zpanel/cnf/db.php /etc/zpanel/panel/cnf/db.php
sed -i "s/\$pass = \"\";/\$pass = \"$MYSQL_PASS\";/g" /etc/zpanel/panel/cnf/db.php
echo "Done." >/dev/tty



echo -n "Importing Zpanel Core Database: " >/dev/tty

mysql -uroot -p$MYSQL_PASS < /etc/zpanel/configs/zpanel_core.sql
mysql -uroot -p$MYSQL_PASS -e "USE zpanel_core; UPDATE x_settings SET so_value_tx = 209715200, so_desc_tx = 'Maximum size in bytes allowed for mailboxes. Default = 209715200 (200 MB)' WHERE so_name_vc = 'max_mail_size' LIMIT 1;"

echo "Done." >/dev/tty



echo -n "Setting up Apache configuration to work with ZPX: " >/dev/tty

DOC_ROOT_LINE=`grep 'sites-enabled' /etc/apache2/apache2.conf  -n | cut -d ":" -f1`
LINE_NO=`expr $DOC_ROOT_LINE + 1`
sed -i "$DOC_ROOT_LINE s/^/#/" /etc/apache2/apache2.conf
echo "Include /etc/zpanel/configs/apache/httpd.conf" >> /etc/apache2/apache2.conf

echo "Done." >/dev/tty



echo -n "Setting up Network info for ZPX and Compiling Default VHOST: " >/dev/tty

/etc/zpanel/panel/bin/setso --set zpanel_domain $SERVER_CP_NAME
/etc/zpanel/panel/bin/setso --set server_ip $SERVER_IP
php /etc/zpanel/panel/bin/daemon.php 

echo "Done." >/dev/tty



echo -n "Configuring Postfix and Dovecot: " >/dev/tty

## build vda support into postfix 2.9.1-4
cd /usr/src
apt-get -y install linux-headers-$(uname -r)
apt-get -y build-dep postfix
apt-get -y source postfix
cd postfix-2.9.1
wget -q http://vda.sourceforge.net/VDA/postfix-vda-v11-2.9.1.patch
patch -p1 < postfix-vda-v11-2.9.1.patch
sed -i "s/export DEB_BUILD_HARDENING=1/export DEB_BUILD_HARDENING=0/g" /usr/src/postfix-2.9.1/debian/rules
dpkg-buildpackage
cd ..

## preload postfix variables to suppress prompts
echo postfix postfix/mailname string $SERVER_NAME | debconf-set-selections
echo postfix postfix/main_mailer_type select Internet Site | debconf-set-selections
## install patched postfix redundant for i386/amd64..
dpkg -i postfix_2.9.1-4_amd64.deb postfix-mysql_2.9.1-4_amd64.deb
dpkg -i postfix_2.9.1-4_i386.deb postfix-mysql_2.9.1-4_i386.deb

apt-get -y install dovecot-mysql dovecot-imapd dovecot-pop3d dovecot-common libsasl2-modules-sql libsasl2-modules 
## (old way, not compatible with 12.04) ## apt-get -y install postfix postfix-mysql dovecot-mysql dovecot-imapd dovecot-pop3d dovecot-common libsasl2-modules-sql libsasl2-modules 
mkdir -p /var/zpanel/vmail
## why are we setting to 777 ???
chmod -R 777 /var/zpanel/vmail
chmod -R g+s /var/zpanel/vmail
groupadd -g 5000 vmail
useradd -g vmail -u 5000 -d /var/zpanel/vmail -s /bin/bash vmail
chown -R vmail.vmail /var/zpanel/vmail
mysql -uroot -p$MYSQL_PASS < /etc/zpanel/configs/postfix/zpanel_postfix.sql
echo "# Dovecot LDA" >> /etc/postfix/master.cf
echo "dovecot   unix  -       n       n       -       -       pipe" >> /etc/postfix/master.cf
echo '  flags=DRhu user=vmail:mail argv=/usr/lib/dovecot/deliver -d ${recipient}' >> /etc/postfix/master.cf
## add MYSQL_PASS to the config files
sed -i "2 i connect = host=127.0.0.1 dbname=zpanel_postfix user=root password=$MYSQL_PASS" /etc/zpanel/configs/postfix/conf/dovecot-sql.conf 
sed -i "2 i password = $MYSQL_PASS" /etc/zpanel/configs/postfix/conf/mysql_relay_domains_maps.cf
sed -i "2 i password = $MYSQL_PASS" /etc/zpanel/configs/postfix/conf/mysql_virtual_alias_maps.cf
sed -i "2 i password = $MYSQL_PASS" /etc/zpanel/configs/postfix/conf/mysql_virtual_domains_maps.cf
sed -i "2 i password = $MYSQL_PASS" /etc/zpanel/configs/postfix/conf/mysql_virtual_mailbox_limit_maps.cf
sed -i "2 i password = $MYSQL_PASS" /etc/zpanel/configs/postfix/conf/mysql_virtual_mailbox_maps.cf
sed -i "2 i password = $MYSQL_PASS" /etc/zpanel/configs/postfix/conf/mysql_virtual_transport.cf
## force account to be active for mail to be delivered
sed -i "s/#additional_/additional_/g" /etc/zpanel/configs/postfix/conf/mysql_virtual_mailbox_maps.cf
## create cf to allow for deletion of accounts and still allow forwards to function
echo "user = root"                       > /etc/zpanel/configs/postfix/conf/mysql_virtual_forwardings_maps.cf
echo "password = $MYSQL_PASS"           >> /etc/zpanel/configs/postfix/conf/mysql_virtual_forwardings_maps.cf
echo "hosts = 127.0.0.1"                >> /etc/zpanel/configs/postfix/conf/mysql_virtual_forwardings_maps.cf
echo "dbname = zpanel_core"             >> /etc/zpanel/configs/postfix/conf/mysql_virtual_forwardings_maps.cf
echo "table = x_forwarders"             >> /etc/zpanel/configs/postfix/conf/mysql_virtual_forwardings_maps.cf
echo "select_field = fw_destination_vc" >> /etc/zpanel/configs/postfix/conf/mysql_virtual_forwardings_maps.cf
echo "where_field = fw_address_vc"      >> /etc/zpanel/configs/postfix/conf/mysql_virtual_forwardings_maps.cf
chmod +x /etc/zpanel/configs/postfix/conf/mysql_virtual_forwardings_maps.cf

## make postfix look at zpanel dir instead of its own
mv /etc/postfix/main.cf /etc/postfix/main.old
ln -s /etc/zpanel/configs/postfix/conf/main.cf /etc/postfix/main.cf

## make dovecot look at zpanel dir instead of its own
mv /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.old
ln -s /etc/zpanel/configs/dovecot2/dovecot.conf /etc/dovecot/dovecot.conf

## set SERVER_NAME in postfix configs
sed -i "s/control.yourdomain.com/$SERVER_NAME/g" /etc/zpanel/configs/postfix/conf/main.cf
sed -i "s/control.youromain.com/$SERVER_NAME/g" /etc/zpanel/configs/postfix/conf/main.cf

## set cf to to allow for deletion of accounts and still allow forwards to function
sed -i "/^virtual_alias_maps/ s/\$/ mysql:\/etc\/zpanel\/configs\/postfix\/conf\/mysql_virtual_forwardings_maps.cf/" /etc/zpanel/configs/postfix/conf/main.cf

## remove virtual quota info that's not supported in postfix 2.9.1
sed -i '/virtual_create_maildirsize/d' /etc/zpanel/configs/postfix/conf/main.cf

## change mailbox quota to maildir quoata
sed -i 's/virtual_mailbox_extended/virtual_maildir_extended/g' /etc/zpanel/configs/postfix/conf/main.cf


echo "Done." >/dev/tty



echo -n "Configuring Roundcube: " >/dev/tty

mysql -uroot -p$MYSQL_PASS < /etc/zpanel/configs/roundcube/zpanel_roundcube.sql
MYSQL_LINE=`grep "mysql:" /etc/zpanel/panel/etc/apps/webmail/config/db.inc.php -n | cut -d ":" -f1`
MYSQL_LINE_NO=`expr $MYSQL_LINE + 1`
sed -i "$MYSQL_LINE_NO i \$rcmail_config['db_dsnw'] = 'mysql://root:$MYSQL_PASS@localhost/zpanel_roundcube';" /etc/zpanel/panel/etc/apps/webmail/config/db.inc.php 

echo "Done." >/dev/tty



echo -n "Installing and Configuring ProFTPD: " >/dev/tty

## preload proftpd variables to suppress prompts
echo proftpd-basic shared/proftpd/inetd_or_standalone select standalone | debconf-set-selections
apt-get -y install proftpd-mod-mysql 
mysql -uroot -p$MYSQL_PASS < /etc/zpanel/configs/proftpd/zpanel_proftpd.sql
groupadd -g 2001 ftpgroup
useradd -u 2001 -s /bin/false -d /bin/null -c "proftpd user" -g ftpgroup ftpuser
SQL_LINE=`grep "SQLConnectInfo" /etc/zpanel/configs/proftpd/proftpd-mysql.conf -n | cut -d ":" -f1`
SQL_LINE_NO=`expr $SQL_LINE + 1`
sed -i "$SQL_LINE s/^/#/" /etc/zpanel/configs/proftpd/proftpd-mysql.conf 
sed -i "$SQL_LINE_NO i SQLConnectInfo  zpanel_proftpd@localhost root $MYSQL_PASS" /etc/zpanel/configs/proftpd/proftpd-mysql.conf 
mv /etc/proftpd/proftpd.conf /etc/proftpd/proftpd.old
touch /etc/proftpd/proftpd.conf
echo "include /etc/zpanel/configs/proftpd/proftpd-mysql.conf" >> /etc/proftpd/proftpd.conf
mkdir /var/zpanel/logs/proftpd
chmod -R 644 /var/zpanel/logs/proftpd

echo "Done." >/dev/tty



echo -n "Installing and Configuring BIND: " >/dev/tty

apt-get -y install bind9 bind9utils 
mkdir /var/zpanel/logs/bind
touch /var/zpanel/logs/bind/bind.log
chmod -R 777 /var/zpanel/logs/bind/bind.log
echo "include \"/etc/zpanel/configs/bind/etc/log.conf\";" >> /etc/bind/named.conf
echo "include \"/etc/zpanel/configs/bind/etc/named.conf\";" >> /etc/bind/named.conf
ln -s /usr/sbin/named-checkconf /usr/bin/named-checkconf 
ln -s /usr/sbin/named-checkzone /usr/bin/named-checkzone 
ln -s /usr/sbin/named-compilezone /usr/bin/named-compilezone 

echo "Done." >/dev/tty



echo -n "Compiling zsudo: " >/dev/tty

cc -o /etc/zpanel/panel/bin/zsudo /etc/zpanel/configs/bin/zsudo.c 
chown root /etc/zpanel/panel/bin/zsudo
chmod +s /etc/zpanel/panel/bin/zsudo

echo "Done." >/dev/tty



echo -n "Setting cron for daemon.php: " >/dev/tty

touch /etc/cron.d/zdaemon
echo "*/5 * * * * root /usr/bin/php -q /etc/zpanel/panel/bin/daemon.php >> /dev/null 2>&1" >> /etc/cron.d/zdaemon
chmod 644 /etc/cron.d/zdaemon

echo "Done." >/dev/tty



echo -n "Registering ZPPY Client: " >/dev/tty

ln -sf /etc/zpanel/panel/bin/zppy /usr/bin/zppy 

echo "Done." >/dev/tty



echo -n "Removing temp files: " >/dev/tty

rm -rf /opt/zpanel 

echo "Done." >/dev/tty



echo "Restarting all necessary services: " >/dev/tty

if [ $? = "0" ]; then
        echo "-- Apache2 Web Server Restarted Successfully" >/dev/tty
fi
sleep 1

/etc/init.d/postfix restart
if [ $? = "0" ]; then
        echo "-- Postfix Server Restarted Successfully" >/dev/tty
fi
sleep 1

/etc/init.d/dovecot restart
if [ $? = "0" ]; then
        echo "-- Dovecot Server Restarted Successfully" >/dev/tty
fi
sleep 1

/etc/init.d/proftpd restart
if [ $? = "0" ]; then
        echo "-- ProFTPD Server Restarted Successfully" >/dev/tty
fi
sleep 1

/etc/init.d/mysql restart
if [ $? = "0" ]; then
        echo "-- MySQL Server Restarted Successfully" >/dev/tty
fi
sleep 1

/etc/init.d/bind9 restart
if [ $? = "0" ]; then
        echo "-- Bind9 Server Restarted Successfully" >/dev/tty
fi



echo -e "\nInstalling ballen/rustus zppy repo and modules: " >/dev/tty

zppy repo add rustus.txt-clan.com 
zppy repo add ballen.co.uk 
zppy update

echo -n "-- gatekeeper: " >/dev/tty
zppy install gatekeeper
echo "installed" >/dev/tty

echo -n "-- system_logviewer: " >/dev/tty
zppy install system_logviewer 
echo "installed" >/dev/tty

echo -n "-- kfm: " >/dev/tty
zppy install kfm 
echo "installed" >/dev/tty

echo -n "-- ftp_browser: " >/dev/tty
zppy install ftp_browser 
echo "installed" >/dev/tty

echo -n "-- visitor_stats: " >/dev/tty
zppy install visitor_stats 
echo "installed" >/dev/tty




## turn output back on
exec 1>/dev/tty



echo ""
echo "====================================================================="
echo "= Installation and Configuration of ZPX on Ubuntu 12.04 is Complete ="
echo "====================================================================="
echo ""
echo "====================================================================="
echo "=    Install Log can be found at $INSTALLLOG"
echo "====================================================================="
echo ""
echo "====================================================================="
echo "=    Please REBOOT the server and open:                             ="
echo "=         http://$SERVER_CP_NAME/zpanel"
echo "=              or                                                   ="
echo "=         http://$SERVER_IP/zpanel"
echo "=                                                                   ="
echo "=         USER: zadmin                                              ="
echo "=         PASS: password (Change on 1st login!)                     ="
echo "====================================================================="
echo ""
echo ""
echo "====================================================================="
echo "=        This script is not written by official ZPX Support         ="
echo "=        Please do not ask them for official support on this        ="
echo "====================================================================="
echo ""
echo ""
echo "=...................................................................="
echo "=                By Xengulai (xengulai@xengulai.com)                ="
echo "=...................................................................="
echo ""
echo ""
echo -e "#############################"
echo -e "# REBOOTING THE SERVER NOW! #"
echo -e "#############################"
shutdown -r now
