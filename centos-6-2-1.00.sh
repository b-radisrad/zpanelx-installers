#!/bin/bash

#################################################################
# ZPanelX Automated Installer for CentOS 6.2                    #
# Created by : nickelj                                          #
# Current maintainer : Kevin Andrews (kandrews@zpanelcp.com)    #
# Licensed Under the GPL (http://www.gnu.org/licenses/gpl.html) #
# Version 1.0.0                                                 #
#################################################################

yum -y install wget chkconfig

r=`wget -q http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-7.noarch.rpm`
if [ $? -ne 0 ]
  then
        echo -e "PROFTPD will currently failed to install\nPlease update the following url to the correct URL:\n"
        echo -e "This url is used in two places in this installation script!\n\n"
        echo -e "http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-*.noarch.rpm\n\n"
        echo -e "Visit http://dl.fedoraproject.org/pub/epel/6/x86_64/ and find the epel-release url."
        exit
fi

tz=``
echo -e "Find your timezone from : http://php.net/manual/en/timezones.php e.g Europe/London"
echo -e ""
read -e -p "Enter Your Time Zone: " tz

echo $tz

password=""
password2="old"
echo -e "Centos 6.2 ZPanelX Official Automated Installer\n\n"
echo -e "This script assumes you have installed Centos 6.2 as either Minimal or Basic Server.\n"
echo -e "If you selected additional options during the CentOS install please consider reinstalling with no additional options.\n\n"
fqdn=`/bin/hostname`
pubip=`curl -s http://automation.whatismyip.com/n09230945.asp`
while true; do
   read -e -p "Enter the FQDN of the server (example: zpanel.yourdomain.com): " -i $fqdn fqdn
   read -e -p "Enter the Public (external) IP of the server: " -i $pubip pubip
   while [ "$password" != "$password2" ]
   do
         password=""
         password2="old"
         echo -e "MySQL Password is currently blank, please change it now.\n"
         prompt="Password you will use for MySQL: "
         while IFS= read -p "$prompt" -r -s -n 1 char 
         do 
               if [[ $char == $'\0' ]] 
               then 
                  break 
               fi
               prompt='*' 
               password+="$char" 
         done
         password2=""
         echo
         prompt="Re-enter the password you will use for MySQL: "
         while IFS= read -p "$prompt" -r -s -n 1 char 
         do 
               if [[ $char == $'\0' ]] 
               then 
                  break 
               fi
               prompt='*' 
               password2+="$char" 
         done
         if [ "$password" != "$password2" ]
         then
            echo -e "\nPasswords did not match!\n"
         fi
   done
   echo -e "\n\nZPanelX Install Configuration Parameters:\n"
   echo -e "Fully Qualified Domain Name: " $fqdn
   echo -e "Public IP address: " $pubip
   echo -e ""
   read -e -p "Proceed with installation (y/n/q)? " yn
   case $yn in
        [Yy]* ) break;;
        [Qq]* ) exit;
   esac
done

echo -e "## PREPARING THE SERVER ##"
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
if [ -e "/etc/init.d/sendmail" ]
then
chkconfig --levels 235 sendmail off
/etc/init.d/sendmail stop
fi   
service iptables save
service iptables stop
chkconfig iptables off

echo -e ""
echo -e "###########################"
echo -e "## Adding PROFTPD REPO   ##"
echo -e "## This can take a while ##"
echo -e "###########################"
echo -e ""

###################################
# PROFTPD REPO                    #
# THIS URL CAN BECOME OUT OF DATE #
###################################
wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-7.noarch.rpm
rpm -Uvh epel-release*rpm
###################################

echo -e "## Removing sendmail and vsftpd"
yum -y remove sendmail vsftpd
echo -e "## Running System Update ##";
yum -y update
echo -e "## Installing vim make zip unzip ld-linux.so.2 libbz2.so.1 libdb-4.7.so libgd.so.2 ##"
yum -y install sudo wget vim make zip unzip git ld-linux.so.2 libbz2.so.1 libdb-4.7.so libgd.so.2
echo -e "## Installing httpd php php-suhosin php-devel php-gd php-mbstring php-mcrypt php-intl php-imap php-mysql php-xml php-xmlrpc curl curl-devel perl-libwww-perl libxml2 libxml2-devel mysql-server zip webalizer gcc gcc-c++ httpd-devel at make mysql-devel bzip2-devel ##"
yum -y -q install httpd php php-suhosin php-devel php-gd php-mbstring php-mcrypt php-intl php-imap php-mysql php-xml php-xmlrpc curl curl-devel perl-libwww-perl libxml2 libxml2-devel mysql-server zip webalizer gcc gcc-c++ httpd-devel at make mysql-devel bzip2-devel
echo -e "## Installing postfix dovecot dovecot-mysql ##"
yum -y install postfix dovecot dovecot-mysql
echo -e "## Installing proftpd proftpd-mysql ##"
yum -y install proftpd proftpd-mysql
echo -e "## Installing bind bind-utils bind-libs ##"
yum -y install bind bind-utils bind-libs

git clone https://github.com/bobsta63/zpanelx.git
cd zpanelx/
git checkout 10.0.0
mkdir ../zpanelexport/
git checkout-index -a -f --prefix=../zpanelexport/
cd ../zpanelexport/

######################
# INSTALL THE PANEL! #
######################
echo -e "## INSTALLING THE PANEL... ##"
cd etc/build/
chmod +x prepare.sh
./prepare.sh
cp -R ../../* /etc/zpanel/panel/
chmod -R 777 /etc/zpanel/
chmod -R 777 /var/zpanel/
chmod 644 /etc/zpanel/panel/etc/apps/phpmyadmin/config.inc.php    
chmod +x /etc/zpanel/panel/bin/zppy
chmod +x /etc/zpanel/panel/bin/setso
cp -R /etc/zpanel/panel/etc/build/config_packs/centos_6_2/* /etc/zpanel/configs/

###################    
# CONFIGURE MYSQL #
###################
echo -e "## CONFIGURE MYSQL ##"
chkconfig --levels 235 mysqld on
service mysqld start
mysqladmin -u root password $password
mysql -u root -p$password -e "DROP DATABASE test";
read -p "Remove access to root MySQL user from remote connections? (Recommended) Y/n " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
mysql -u root -p$password -e "DELETE FROM mysql.user WHERE User='root' AND Host!='localhost'";
echo "Remote access to the root MySQL user has been removed"
else
echo "Remote access to the root MySQL user is still available, we hope you selected a very strong password"
fi
mysql -u root -p$password -e "DELETE FROM mysql.user WHERE User=''";
mysql -u root -p$password -e "FLUSH PRIVILEGES";


##############################
# SET ZPANEL DATABASE CONFIG #
##############################
cat > /etc/zpanel/panel/cnf/db.php <<EOF
<?php

/**
 * Database configuration file.
 * @package zpanelx
 * @subpackage core -> config
 * @author Bobby Allen (ballen@zpanelcp.com)
 * @copyright ZPanel Project (http://www.zpanelcp.com/)
 * @link http://www.zpanelcp.com/
 * @license GPL (http://www.gnu.org/licenses/gpl.html)
 */
\$host = "localhost";
\$dbname = "zpanel_core";
\$user = "root";
\$pass = "$password";
?>
EOF

    
#########################
# IMPORT PANEL DATABASE #
#########################
mysql -uroot -p$password < /etc/zpanel/configs/zpanel_core.sql

####################
# CONFIGURE APACHE #
####################
echo "Include /etc/zpanel/configs/apache/httpd.conf" >> /etc/httpd/conf/httpd.conf

#Change default docroot
sed -i 's|DocumentRoot "/var/www/html"|DocumentRoot "/etc/zpanel/panel"|' /etc/httpd/conf/httpd.conf

#Set ZPanel Network info and compile the default vhost.conf
/etc/zpanel/panel/bin/setso --set zpanel_domain $fqdn
/etc/zpanel/panel/bin/setso --set server_ip $pubip

# Set PHP Time Zone
sed -i "s|;date.timezone =|date.timezone = $tz|" /etc/php.ini
#upload directory
sed -i "s|;upload_tmp_dir =|upload_tmp_dir = /var/zpanel/temp/|" /etc/php.ini
chown -R apache:apache /var/zpanel/temp/

php /etc/zpanel/panel/bin/daemon.php

echo "127.0.0.1 "$fqdn >> /etc/hosts
chkconfig --levels 235 httpd on
service httpd start

echo "apache ALL=NOPASSWD: /etc/zpanel/panel/bin/zsudo" >> /etc/sudoers

###########################################
# POSTFIX-DOVECOT (CentOS6 uses Dovecot2) #
###########################################
mkdir -p /var/zpanel/vmail
chmod -R 777 /var/zpanel/vmail
chmod -R g+s /var/zpanel/vmail
groupadd -g 5000 vmail
useradd -m -g vmail -u 5000 -d /var/zpanel/vmail -s /bin/bash vmail
chown -R vmail.vmail /var/zpanel/vmail
    
mysql -uroot -p$password < /etc/zpanel/configs/postfix/zpanel_postfix.sql

# Postfix Master.cf
echo "# Dovecot LDA" >> /etc/postfix/master.cf
echo "dovecot   unix  -       n       n       -       -       pipe" >> /etc/postfix/master.cf
echo '  flags=DRhu user=vmail:vmail argv=/usr/libexec/dovecot/deliver -d ${recipient}' >> /etc/postfix/master.cf

#Edit these files and add mysql root and password:
sed -i "s|YOUR_ROOT_MYSQL_PASSWORD|$password|" /etc/zpanel/configs/postfix/conf/dovecot-sql.conf
sed -i "s|#connect|connect|" /etc/zpanel/configs/postfix/conf/dovecot-sql.conf
sed -i "s|#password = YOUR_ROOT_MYSQL_PASSWORD|password = $password|" /etc/zpanel/configs/postfix/conf/mysql_relay_domains_maps.cf
sed -i "s|#password = YOUR_ROOT_MYSQL_PASSWORD|password = $password|" /etc/zpanel/configs/postfix/conf/mysql_virtual_alias_maps.cf
sed -i "s|#password = YOUR_ROOT_MYSQL_PASSWORD|password = $password|" /etc/zpanel/configs/postfix/conf/mysql_virtual_domains_maps.cf
sed -i "s|#password = YOUR_ROOT_MYSQL_PASSWORD|password = $password|" /etc/zpanel/configs/postfix/conf/mysql_virtual_mailbox_limit_maps.cf
sed -i "s|#password = YOUR_ROOT_MYSQL_PASSWORD|password = $password|" /etc/zpanel/configs/postfix/conf/mysql_virtual_mailbox_maps.cf
sed -i "s|#password = YOUR_ROOT_MYSQL_PASSWORD|password = $password|" /etc/zpanel/configs/postfix/conf/mysql_virtual_transport.cf
        
mv /etc/postfix/main.cf /etc/postfix/main.old
ln /etc/zpanel/configs/postfix/conf/main.cf /etc/postfix/main.cf
mv /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.old
ln -s /etc/zpanel/configs/dovecot2/dovecot.conf /etc/dovecot/dovecot.conf

sed -i "s|myhostname = control.yourdomain.com|myhostname = $fqdn|" /etc/zpanel/configs/postfix/conf/main.cf
# This next line is not a typo - the original file has youromain.com
sed -i "s|mydomain   = control.youromain.com|mydomain   = $fqdn|" /etc/zpanel/configs/postfix/conf/main.cf
    
chkconfig --levels 345 postfix on
chkconfig --levels 345 dovecot on
service postfix start
service dovecot start

################################################################    
# Server will need a reboot for postfix to be fully functional #
################################################################

#############    
# ROUNDCUBE #
#############

mysql -uroot -p$password < /etc/zpanel/configs/roundcube/zpanel_roundcube.sql
sed -i "s|YOUR_ROOT_MYSQL_PASSWORD|$password|" /etc/zpanel/panel/etc/apps/webmail/config/db.inc.php
sed -i "s|#||" /etc/zpanel/panel/etc/apps/webmail/config/db.inc.php
    
###########    
# PROFTPD #
###########

mysql -uroot -p$password < /etc/zpanel/configs/proftpd/zpanel_proftpd.sql
groupadd -g 2001 ftpgroup
useradd -u 2001 -s /bin/false -d /bin/null -c "proftpd user" -g ftpgroup ftpuser

sed -i "s|zpanel_proftpd@localhost root z|zpanel_proftpd@localhost root $password|" /etc/zpanel/configs/proftpd/proftpd-mysql.conf
    
mv /etc/proftpd.conf /etc/proftpd.old
touch /etc/proftpd.conf
echo "include /etc/zpanel/configs/proftpd/proftpd-mysql.conf" >> /etc/proftpd.conf
mkdir /var/zpanel/logs/proftpd
chmod -R 644 /var/zpanel/logs/proftpd
    
chkconfig --levels 345 proftpd on
service proftpd start

########    
# BIND #
########

#CONFIGURE BIND AS NEEDED - ONCE RUNNING INCLUDE ZPANEL NAMED PATH
#vi /etc/named.conf 

cat > /etc/named.conf <<EOF
//
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//
// See /usr/share/doc/bind*/sample/ for example named configuration files.
//

options {
	listen-on port 53 { any; };
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
	allow-query	{ any; };
	recursion yes;

	dnssec-enable yes;
	dnssec-validation yes;
	dnssec-lookaside auto;

	/* Path to ISC DLV key */
	bindkeys-file "/etc/named.iscdlv.key";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
	type hint;
	file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/zpanel/configs/bind/etc/named.conf";
EOF


#chmod or apache can't write to the folder
chmod -R 777 /etc/zpanel/configs/bind/zones/
chkconfig --levels 345 named on
service named start

################
# ZPANEL ZSUDO #
################

# Must be owned by root with 4777 permissions, or zsudo will not work!
cc -o /etc/zpanel/panel/bin/zsudo /etc/zpanel/configs/bin/zsudo.c
sudo chown root /etc/zpanel/panel/bin/zsudo
chmod +s /etc/zpanel/panel/bin/zsudo

#################    
# ZPANEL DAEMON #
#################
touch /etc/cron.d/zdaemon

#PATH added so service can be run as a command via daemon cron job
cat > /etc/cron.d/zdaemon <<EOF
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root
HOME=/
*/5 * * * * root /usr/bin/php -q /etc/zpanel/panel/bin/daemon.php >> /dev/null 2>&1
EOF

# Permissions must be 644 or cron will not run!
sudo chmod 644 /etc/cron.d/zdaemon
service crond restart

####################
# GET CRON WORKING #
####################
touch /var/spool/cron/apache
touch /etc/cron.d/apache
chmod -R 777 /var/spool/cron/
chmod 644 /var/spool/cron/apache 
chown -R apache:root /var/spool/cron/
service crond reload
crontab -u apache /var/spool/cron/apache

#########################
# REMOVE WEBALIZER CONF #
#########################
mv /etc/webalizer.conf /etc/webalizer.conf.old

#################
# REBOOT SERVER #
#########################################
#                                       #
# DONT YOU DARE SKIP THIS STEP          #
# ELSE DONT POST FOR SUPPORT ABOUT MAIL #
# NOT WORKING!                          #
#                                       #
#########################################
echo -e "#############################"
echo -e "# REBOOTING THE SERVER NOW! #"
echo -e "#############################"
shutdown -r now

