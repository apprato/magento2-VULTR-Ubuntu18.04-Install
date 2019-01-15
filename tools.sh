#!/bin/bash

# description: Setup VULTR for user, create system user install  docker, docker-compose
# Environment settings

INSTALL_DIR=`echo $0 | sed 's/tools\.sh//g'`
set -x

installPHP() {
  
  sudo apt install php7.2-common -y
  sudo apt install php7.2-cli -y
  sudo apt install php7.2-fpm -y 
  sudo apt install php7.2-opcache -y
  sudo apt install php7.2-gd -y
  sudo apt install php7.2-mysql -y 
  sudo apt install php7.2-curl -y
  sudo apt install php7.2-intl -y
  sudo apt install php7.2-xsl -y
  sudo apt install php7.2-mbstring -y 
  sudo apt install php7.2-zip -y
  sudo apt install php7.2-bcmath -y
  sudo apt install php7.2-soap -y

  # Check if php-fpm is working
  sudo systemctl status php7.2-fpm
	
}


configurePHP () {
  
  sudo sed -i "s/memory_limit = .*/memory_limit = 1024M/" /etc/php/7.2/fpm/php.ini
  sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = 256M/" /etc/php/7.2/fpm/php.ini
  sudo sed -i "s/zlib.output_compression = .*/zlib.output_compression = on/" /etc/php/7.2/fpm/php.ini
  sudo sed -i "s/max_execution_time = .*/max_execution_time = 18000/" /etc/php/7.2/fpm/php.ini
  sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.2/fpm/php.ini
  sudo sed -i "s/;opcache.save_comments.*/opcache.save_comments = 1/" /etc/php/7.2/fpm/php.ini	
}	

installPool () {

  # Make sure to run as root
  user="$(id -un 2>/dev/null || true)"

  if [ "$user" != 'root' ]; then
    echo "Please try again as root"
    return 1
  fi

  # Add Magento $username user and group
  echo "Please enter the username selected for magento"
  read username

  cat <<EOT >> /etc/php/7.2/fpm/pool.d/$username.conf
[$username]
user = $username
group = www-data
listen.owner = $username
listen.group = www-data
listen = /var/run/php/php7.2-fpm-$username.sock
pm = ondemand
pm.max_children = 1000
pm.process_idle_timeout = 10s;
pm.max_requests = 10000
chdir = /
EOT

sudo systemctl restart php7.2-fpm
# Was the socket created
ls -al /var/run/php/php7.2-fpm-$username.sock

}	

installMagentoUser() {

  # Make sure to run as root
  user="$(id -un 2>/dev/null || true)"

  if [ "$user" != 'root' ]; then
    echo "Please try again as root"
    return 1
  fi

  # Add Magento $username user and group
  echo "Please enter the magento username"
  read username
  sudo useradd -m -U -r -d /opt/$username $username

  # Add the www-data user to the $username group & ensure nGinx can access /opt/$username  
  sudo usermod -a -G $username www-data
  sudo chmod 750 /opt/$username

}	


installNginx() {
  
  sudo apt update
  sudo apt install nginx
  sudo systemctl status nginx
  # Open ports 80 & 443
  sudo ufw allow 'Nginx Full' 
  sudo ufw status

}  


installMySQL () {
  sudo apt install mysql-server mysql-client
  echo "Now you need to create a database called magento.  Create a user with a passowrd and Grant it permissions to the table:"
  echo "$ sudo mysql"
  echo "mysql > CREATE DATABASE magento;"
  echo "mysql > GRANT ALL ON magento.* TO 'magento'@'localhost' IDENTIFIED BY 'strict-password'"  
  echo "mysql > EXIT;"

}	


installComposer () {
  curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
  composer --version
}


configureNginx () {


  # Make sure to run as root
  user="$(id -un 2>/dev/null || true)"

  if [ "$user" != 'root' ]; then
    echo "Please try again as root"
    return 1
  fi

  # Add Magento $username user and group
  echo "Please enter the username selected for magento"
  read username
  echo "Please enter the url to use (E.g. example.com"
  

  cat <<EOT >> /etc/nginx/sites-available/example.com
upstream fastcgi_backend {
  server   unix:/var/run/php/php7.2-fpm-magento.sock;
}

server {
    listen 80;
    server_name example.com www.example.com;

    include snippets/letsencrypt.conf;
    return 301 https://example.com$request_uri;
}

server {
    listen 443 ssl http2;
    server_name www.example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
    include snippets/ssl.conf;
    include snippets/letsencrypt.conf;

    return 301 https://example.com$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
    include snippets/ssl.conf;
    include snippets/letsencrypt.conf;

    set $MAGE_ROOT /opt/magento/public_html;
    set $MAGE_MODE developer; # or production

    access_log /var/log/nginx/example.com-access.log;
    error_log /var/log/nginx/example.com-error.log;

    include /opt/magento/public_html/nginx.conf.sample;

EOT
}	

deployCode () {
  php bin/magento setup:upgrade
  php bin/magento setup:static-content:deploy -f -a frontend en_AU en_US
  php bin/magento setup:static-content:deploy -f -a adminhtml en_AU en_US
  php bin/magento cache:clean && magento cache:flush

  @TODO
  #sudo chown -R www-data:www-data /var/www/magento2.com/*
  #sudo chmod -R 0777 /var/www/magento2.com/var /var/www/magento2.com/pub/media /var/www/magento2.com/pub/static app/etc /var/www/magento2.com/generated
  #sudo chmod -R 0775 bin/magento
  #sudo find . -type d -exec chmod 775 {} \;
  #sudo find . -type f -exec chmod 664 {} \;
  #sudo chmod -R g+s .

}


installRcLocalService () {

  echo  "Create a service:"
  cp rc-local.service /etc/systemd/system/rc-local.service
  
  echo "Create and make sure /etc/rc.local is executable and add this code inside it:"
  cp rc.local /etc
  sudo chmod +x /etc/rc.local
  
  echo "Enable the service:"
  sudo systemctl enable rc-local

}


case "$1" in
  installRcLocalService)
    installRcLocalService
    ;;
  installNginx)
    installNginx
    ;;  
  installMySQL)
    installMySQL
    ;;
  installMagentoUser)
    installMagentoUser
    ;;
  installPHP)
    installPHP
    ;;
  configurePHP)
    configurePHP
    ;;    
  installPool)
    installPool
    ;;
  installComposer)
    installComposer
    ;;  
  *)
echo "
SYNOPSIS
    sh tools.sh
    sh tools.sh [-- [OPTIONS...]] [-- [ENVIRONMENT...]]

DESCRIPTION
    Setup access user, install docker, docker-compose 

OPTIONS
    installRcLocalService                     Install /etc/rc.local to run commands when the system is rebooted.
    installNginx                              Install nGInx and open ports 80 & 443 on firewall
    installMySQL 		              installMySQL
    installMagentoUser                        installMagentoUser
    installPHP                                installPHP, php-fpm
    configurePHP			      configurePHP
    installPool				      installPool

EXAMPLES
    # Install nGinx
    # sh tools.sh installNginx

"
    >&2
    exit 1
    ;;
esac

