# magento2-VULTR-Ubuntu18.04-Install
Installing and configuring Magento 2 on VULTR Hosting with Ubuntu18.04 with composer
This is intended as a utility script to setup Magento2 on a Ubuntu 18.04 server on VULTR or AWS
Use your chosen magento user which will run the www-data files in PHP and nginx.

## Install server services
$ sh tools.sh installMagentoUser <br />
$ sh tools.sh installMySQL <br />
Create your database and grant all privilidges to the use with a password <br />
(Replace strict-password and magento with your chosen password and database name) <br />
$ mysql <br />
$ mysql > CREATE DATABASE magento;" <br />
$ mysql > GRANT ALL ON magento.* TO 'magento'@'localhost' IDENTIFIED BY 'strict-password'" <br /> 
$ mysql > EXIT;" <br />
$ sh tools.sh installNginx <br />
$ sh tools.sh installPHP <br />
$ sh tools.sh installPool <br />


## Configure server services
Become the root user <br />
$ sh tools.sh configurePHP <br />
$ sh tools.sh configureNginx <br />
$ sh tools.sh confirmNginxConfiguration <br />
