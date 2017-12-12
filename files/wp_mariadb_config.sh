#log to journal showing script start

#execute wp_mariadb_config.sql statements as the root mysql user, 
sudo mysql -u root < mariadb_security_config.sql

#Disable the wp_mariadb_config.service
systemctl disable wp_mariadb_config.service
