#log to journal showing script start
systemd-cat -p "Starting the daemon --Amar" -t wp_mariadb_config printf "%s" "wp_mariadb_config.sh start" 

#execute wp_mariadb_config.sql statements as the root mysql user, 

sudo mysql -u root < mariadb_security_config.sql

#Disable the wp_mariadb_config.service
systemctl disable wp_mariadb_config.service

#log to journal showing script end
systemd-cat -p "Ending the daemon --Amar" -t wp_mariadb_config printf "%s" "wp_mariadb_config.sh end" 
