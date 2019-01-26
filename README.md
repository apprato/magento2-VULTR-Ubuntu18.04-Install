# magento2-VULTR-Ubuntu18.04-Install
Installing and configuring Magento 2 on VULTR Hosting with Ubuntu18.04 with composer
This is intended as a utility script to setup Magento2 on a Ubuntu 18.04 server on VULTR or AWS
Use your chosen magento user which will run the www-data files in PHP and nginx.

## Install server services
$ sh tools.sh installMagentoUser
$ sh tools.sh installMySQL
Create your database and grant all privilidges to the use with a password 
(Replace strict-password and magento with your chosen password and database name)
$ mysql
$ mysql > CREATE DATABASE magento;"
$ mysql > GRANT ALL ON magento.* TO 'magento'@'localhost' IDENTIFIED BY 'strict-password'"  
$ mysql > EXIT;"
$ sh tools.sh installNginx
$ sh tools.sh installPHP
$ sh tools.sh installPool


## Configure server services
Become the root user
$ sh tools.sh configurePHP
$ sh tools.sh configureNginx
$ sh tools.sh confirmNginxConfiguration
