#!/bin/bash

###
###     Auto Installer for ZPX Ubuntu 10.04 LTS
###

clear
echo ""
echo "================================================"
echo "Starting Auto Installer for ZPX for Ubuntu 11.10"
echo "By Mudasir Mirza"
echo "================================================"
sleep 2

clear

[ -f /etc/init.d/apparmor ]
        if [ $? = "0" ]; then
        echo -e "\n\n"
        echo "============================="
        echo "Stopping and Removing AppArmor"
        echo "============================="
        echo ""
        sleep 2
                /etc/init.d/apparmor stop &> /dev/null
                update-rc.d -f apparmor remove &> /dev/null
                apt-get -y remove apparmor
                mv /etc/init.d/apparmor /etc/init.d/apparmpr.removed &> /dev/null
        echo -e "\n\n"
        echo "Done."
        echo -e "\n\n"
        echo -e "\t\t PLEASE REBOOT THE SERVER AND RUN THE SCRIPT AGAIN...\n\n"
        exit
        fi

clear

echo -e "\n"
echo "=========================="
echo "Updating Aptitude Repos..."
echo "=========================="
echo -e "\n"
sleep 2
apt-get update
apt-get -y install unzip
echo -e "\n"
echo "Done."

clear

# Step 1, preparing directory structure
clear
echo ""
echo "===================================="
echo "ZPanel Enviroment Configuration Tool"
echo "===================================="
echo ""
sleep 2
echo "If you need help, please visit our forums: http://forums.zpanelcp.com/"
echo ""
echo "Creating folder structure.."
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
echo "Directory Structure Complete!"
echo "Setting permissions.."
chmod -R 777 /etc/zpanel/
chmod -R 777 /var/zpanel/
echo "Complete!"
echo "Complete!"
echo ""
echo ""
echo "The Zpanel directories have now been created in /etc/zpanel and /var/zpanel"
echo ""

clear

echo ""
echo "======================================================================="
echo "Downloading and Extracting ZPX From SF to Temp Directory at /opt/zpanel"
echo "======================================================================="
echo ""
sleep 2
mkdir /opt/zpanel/
cd /opt/zpanel ; wget http://sourceforge.net/projects/zpanelcp/files/releases/10.0.0/zpanelx-1_0_0.zip/download
cd /opt/zpanel ; unzip *
echo ""
echo "Done..."

echo ""
echo "===================================="
echo "Copying ZpanelX files to /etc/zpanel"
echo "===================================="
cd /opt/zpanel
cp -fr * /etc/zpanel/panel
chmod -R 777 /etc/zpanel/
chmod -R 777 /var/zpanel/
chmod 644 /etc/zpanel/panel/etc/apps/phpmyadmin/config.inc.php
cp -fr /etc/zpanel/panel/etc/build/config_packs/ubuntu_11_10/* /etc/zpanel/configs/

clear

echo ""
echo "==========================="
echo "Registering 'zppy' client.."
echo "==========================="
echo ""
sleep 2
ln -sf /etc/zpanel/panel/bin/zppy /usr/bin/zppy
chmod +x /usr/bin/zppy
ln -sf /etc/zpanel/panel/bin/setso /usr/bin/setso
chmod +x /usr/bin/setso
echo ""
echo "Done."

clear

echo ""
echo "==============================================="
echo "Installing all main required packages"
echo "Please enter password for mysql root when asked"
echo "==============================================="
echo ""
sleep 2
apt-get -y install mysql-server mysql-server apache2 libapache2-mod-php5 libapache2-mod-bw php5-common php5-suhosin php5-cli php5-mysql php5-gd php5-mcrypt php5-curl php-pear php5-imap php5-xmlrpc php5-xsl libdb4.7 zip webalizer build-essential
echo ""
echo ""
echo "Done."

clear

echo ""
echo "==================================="
echo "Setting up MySQL required settings."
echo "==================================="
echo ""
sleep 2

echo ""
echo "Please enter MySQL root password which you set earlier."
read MYSQL_PASS
echo ""
echo "<?php" > /etc/zpanel/panel/cnf/db.php
echo "" >> /etc/zpanel/panel/cnf/db.php
echo "/**" >> /etc/zpanel/panel/cnf/db.php
echo " * Database configuration file." >> /etc/zpanel/panel/cnf/db.php
echo " * @package zpanelx" >> /etc/zpanel/panel/cnf/db.php
echo " * @subpackage core -> config" >> /etc/zpanel/panel/cnf/db.php
echo " * @author Bobby Allen (ballen@zpanelcp.com)" >> /etc/zpanel/panel/cnf/db.php
echo " * @copyright ZPanel Project (http://www.zpanelcp.com/)" >> /etc/zpanel/panel/cnf/db.php
echo " * @link http://www.zpanelcp.com/" >> /etc/zpanel/panel/cnf/db.php
echo " * @license GPL (http://www.gnu.org/licenses/gpl.html)" /etc/zpanel/panel/cnf/db.php
echo " */" >> /etc/zpanel/panel/cnf/db.php
echo "\$host = \"localhost\";" >> /etc/zpanel/panel/cnf/db.php
echo "\$dbname = \"zpanel_core\";" >> /etc/zpanel/panel/cnf/db.php
echo "\$user = \"root\";" >> /etc/zpanel/panel/cnf/db.php
echo "\$pass = \"$MYSQL_PASS\";" >>/etc/zpanel/panel/cnf/db.php
echo "?>" >> /etc/zpanel/panel/cnf/db.php
echo ""
echo "================================="
echo " Importing Zpanel Core Database "
echo "================================="
sleep 1
mysql -uroot -p$MYSQL_PASS < /etc/zpanel/configs/zpanel_core.sql
echo ""
echo "Done"

echo ""
echo "================================================"
echo "Setting up Apache configuration to work with ZPX"
echo "================================================"
DOC_ROOT_LINE=`grep 'sites-enabled' /etc/apache2/apache2.conf  -n | cut -d ":" -f1`
LINE_NO=`expr $DOC_ROOT_LINE + 1`
sed -i "$DOC_ROOT_LINE s/^/#/" /etc/apache2/apache2.conf
echo "Include /etc/zpanel/configs/apache/httpd.conf" >> /etc/apache2/apache2.conf
echo ""
echo "Done"

clear

echo ""
echo "==========================================================="
echo "Setting up Network info for ZPX and Compiling Default VHOST"
echo "==========================================================="
echo ""
sleep 2
echo "Please enter desired FQDN (Full domain name) for ZPX"
echo "Example panel.zpanelcp.com"
read FULL_DOMAIN
echo ""
echo "Please enter your public IP Address"
read IP_ADDR
echo ""
/etc/zpanel/panel/bin/setso --set zpanel_domain $FULL_DOMAIN
/etc/zpanel/panel/bin/setso --set server_ip $IP_ADDR
php /etc/zpanel/panel/bin/daemon.php
echo ""
echo ""
echo "Done..."

clear

echo ""
echo "=============================================="
echo "Starting configuration for Postfix and Dovecot"
echo "=============================================="
echo ""
echo "For Postfix Please Select \"INTERNET SITE\""
echo ""
sleep 4
apt-get -y install postfix postfix-mysql dovecot-mysql dovecot-imapd dovecot-pop3d dovecot-common libsasl2-modules-sql libsasl2-modules
mkdir -p /var/zpanel/vmail
chmod -R 777 /var/zpanel/vmail
chmod -R g+s /var/zpanel/vmail
groupadd -g 5000 vmail
useradd -m -g vmail -u 5000 -d /var/zpanel/vmail -s /bin/bash vmail
chown -R vmail.vmail /var/zpanel/vmail
mysql -uroot -p$MYSQL_PASS < /etc/zpanel/configs/postfix/zpanel_postfix.sql
echo "# Dovecot LDA" >> /etc/postfix/master.cf
echo "dovecot   unix  -       n       n       -       -       pipe" >> /etc/postfix/master.cf
echo '  flags=DRhu user=vmail:mail argv=/usr/lib/dovecot/deliver -d ${recipient}' >> /etc/postfix/master.cf
sed -i "2 i connect = host=127.0.0.1 dbname=zpanel_postfix user=root password=$MYSQL_PASS" /etc/zpanel/configs/postfix/conf/dovecot-sql.conf
sed -i "2 i password = $MYSQL_PASS" /etc/zpanel/configs/postfix/conf/mysql_relay_domains_maps.cf
sed -i "2 i password = $MYSQL_PASS" /etc/zpanel/configs/postfix/conf/mysql_virtual_alias_maps.cf
sed -i "2 i password = $MYSQL_PASS" /etc/zpanel/configs/postfix/conf/mysql_virtual_domains_maps.cf
sed -i "2 i password = $MYSQL_PASS" /etc/zpanel/configs/postfix/conf/mysql_virtual_mailbox_limit_maps.cf
sed -i "2 i password = $MYSQL_PASS" /etc/zpanel/configs/postfix/conf/mysql_virtual_mailbox_maps.cf
sed -i "2 i password = $MYSQL_PASS" /etc/zpanel/configs/postfix/conf/mysql_virtual_transport.cf
mv /etc/postfix/main.cf /etc/postfix/main.old
ln /etc/zpanel/configs/postfix/conf/main.cf /etc/postfix/main.cf
mv /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.old
ln -s /etc/zpanel/configs/dovecot2/dovecot.conf /etc/dovecot/dovecot.conf
sed -i "s/control.yourdomain.com/$FULL_DOMAIN/g" /etc/zpanel/configs/postfix/conf/main.cf

clear

echo ""
echo "================================"
echo "Starting Roundcube configuration"
echo "================================"
echo ""
sleep 2
mysql -uroot -p$MYSQL_PASS < /etc/zpanel/configs/roundcube/zpanel_roundcube.sql
MYSQL_LINE=`grep "mysql:" /etc/zpanel/panel/etc/apps/webmail/config/db.inc.php -n | cut -d ":" -f1`
MYSQL_LINE_NO=`expr $MYSQL_LINE + 1`
sed -i "$MYSQL_LINE_NO i \$rcmail_config['db_dsnw'] = 'mysql://root:$MYSQL_PASS@localhost/zpanel_roundcube';" /etc/zpanel/panel/etc/apps/webmail/config/db.inc.php
echo ""
echo "Done."

clear

echo ""
echo "==============================================="
echo "Starting ProFTPD Installation and Configuration"
echo "==============================================="
echo ""
echo "Please select \"STAND-ALONE\""
sleep 4
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
echo ""
echo ""
echo "Done."

clear

echo ""
echo "============================================="
echo "Starting BIND Installation and Configuration."
echo "============================================="
echo ""
sleep 2
apt-get -y install bind9 bind9utils
mkdir /var/zpanel/logs/bind
touch /var/zpanel/logs/bind/bind.log
chmod -R 777 /var/zpanel/logs/bind/bind.log
echo "include \"/etc/zpanel/configs/bind/etc/log.conf\";" >> /etc/bind/named.conf
echo "include \"/etc/zpanel/configs/bind/etc/named.conf\";" >> /etc/bind/named.conf
ln -s /usr/sbin/named-checkconf /usr/bin/named-checkconf
ln -s /usr/sbin/named-checkzone /usr/bin/named-checkzone
ln -s /usr/sbin/named-compilezone /usr/bin/named-compilezone
echo ""
echo ""
echo "Done."

clear

echo ""
echo "==================================="
echo " Starting zsudo and daemon setting."
echo "==================================="
echo ""
sleep 2
echo "Compiling zsudo"
cc -o /etc/zpanel/panel/bin/zsudo /etc/zpanel/configs/bin/zsudo.c
chown root /etc/zpanel/panel/bin/zsudo
chmod +s /etc/zpanel/panel/bin/zsudo
echo ""
echo "Setting cron for daemon.php"
echo ""

touch /etc/cron.d/zdaemon
echo "*/5 * * * * root /usr/bin/php -q /etc/zpanel/panel/bin/daemon.php >> /dev/null 2>&1" >> /etc/cron.d/zdaemon
chmod 644 /etc/cron.d/zdaemon

echo ""
echo ""
echo "Done."

clear

echo ""
echo "========================="
echo " Registering ZPPY Client."
echo "========================="
echo ""
sleep 2
ln -sf /etc/zpanel/panel/bin/zppy /usr/bin/zppy
echo ""
echo ""
echo "Done."

clear

echo ""
echo "================================="
echo "Restarting all necessary services"
echo "================================="
echo ""
sleep 2
echo ""
echo ""
/etc/init.d/apache2 restart
if [ $? = "0" ]; then
		echo ""
        echo "Apache2 Web Server Restarted Successfully"
        echo ""
fi
sleep 1

/etc/init.d/postfix restart
if [ $? = "0" ]; then
		echo ""
        echo "Postfix Server Restarted Successfully"
        echo ""
fi
sleep 1

/etc/init.d/dovecot restart
if [ $? = "0" ]; then
		echo ""
        echo "Dovecot Server Restarted Successfully"
        echo ""
fi
sleep 1

/etc/init.d/proftpd restart
if [ $? = "0" ]; then
		echo ""
        echo "ProFTPD Server Restarted Successfully"
        echo ""
fi
sleep 1

/etc/init.d/mysql restart
if [ $? = "0" ]; then
		echo ""
        echo "MySQL Server Restarted Successfully"
        echo ""
fi
sleep 1

/etc/init.d/bind9 restart
if [ $? = "0" ]; then
		echo ""
        echo "Bind9 Server Restarted Successfully"
        echo ""
fi
sleep 4

clear

echo ""
echo ""
echo ""
echo "===================================================================="
echo "Installation and Configuration of ZPX on Ubuntu 11.10 is Complete..."
echo "===================================================================="
echo ""
echo ""
echo "Please reboot the server and open http://$FULL_DOMAIN/panel or http://$IP_ADDR/panel"
echo "USER: zadmin"
echo "PASS: password (Change on 1st login!)"
echo ""
echo ""
echo "This script is not written by official ZPX Support"
echo "So please do not ask them for official support on this"
echo "For further support on this please email at mudasirmirza@gmail.com"
echo ""
echo ""
echo "Enjoy the ZPX... :)"
echo ""
echo ""
