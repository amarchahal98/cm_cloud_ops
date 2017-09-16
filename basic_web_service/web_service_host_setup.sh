#!/bin/bash

# Remove pre-existing network file, and replace it with the following content
rm -rf /etc/sysconfig/network-scripts/ifcfg-enp0s3
touch /etc/sysconfig/network-scripts/ifcfg-enp0s3
sudo echo "TYPE=Ethernet 
BOOTPROTO=none 
DEFROUTE=yes 
PEERDNS=yes 
PEERROUTES=yes 
IPV4_FAILURE_FATAL=no 
NAME=enp0s3 
DEVICE=enp0s3 
ONBOOT=yes 
IPADDR=192.168.254.10 
NETMASK=255.255.255.0 
NETWORK=192.168.254.0 
GATEWAY=192.168.254.1
DNS1=142.232.221.253" > /etc/sysconfig/network-scripts/ifcfg-enp0s3

# Public is the default zone
sudo systemctl restart network
sudo firewall-cmd --zone=public --add-port=22/tcp --permanent
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
sudo firewall-cmd --zone=public --add-port=443/tcp --permanent

# Install Packages
sudo yum install -y epel-release 
sudo yum install -y nginx mariadb-server mariadb php php-mysql php-fpm
sudo yum install -y kernel-devel kernel-headers dkms gcc gcc-c++ kexec-tools
sudo yum install -y @base

# Manage services
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl start mariadb
sudo systemctl enable mariadb
echo "# Set root password
UPDATE mysql.user SET Password=PASSWORD('nasp19') WHERE User='root';

# Remove anonymous users
DELETE FROM mysql.user WHERE User='';

# Disallow remote root login
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

# Remove test database
DROP DATABASE test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\\_%';" > mariadb_security_config.sql


# No root password has been set yet, although after the following line and mariadb service restart, the password will be set.
sudo mysql -u root < mariadb_security_config.sql


sudo cat > /etc/nginx/nginx.conf << EOF
# For more information on configuration, see:
#   * Official English Documentation: http://nginx.org/en/docs/
#   * Official Russian Documentation: http://nginx.org/ru/docs/

user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;

    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  _;
        root         /usr/share/nginx/html;
	index index.php index.html index.htm;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        location / {
        }

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
	location ~ \.php$ {
	    try_files \$uri =404;
	    fastcgi_pass unix:/var/run/php-fpm/php-fpm.sock;
            fastcgi_index index.php;
	    fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
	    include fastcgi_params;
        }
    }
}


EOF

# Edit configuration files

sudo sed -i 's/;cgi.fix_pathinfo=0/cgi.fix_pathinfo=1/g' /etc/php.ini
sudo sed -i 's/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm\/php-fpm.sock/g' /etc/php-fpm.d/www.conf
sudo sed -i '31,32s/.//' /etc/php-fpm.d/www.conf
sudo sed -i 's/user = apache/user = nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i 's/group = apache/group = nginx/g' /etc/php-fpm.d/www.conf
sudo systemctl start php-fpm
sudo systemctl enable php-fpm

sudo touch /usr/share/nginx/html/info.php

sudo echo "<?php phpinfo(); ?>" > /usr/share/nginx/html/info.php

sudo echo -n "## Wordpress Database Setup
CREATE DATABASE wordpress;
CREATE USER wordpress_user@localhost IDENTIFIED BY 'nasp19';
GRANT ALL PRIVILEGES ON wordpress.* TO wordpress_user@localhost;

# Reload privilege tables
FLUSH PRIVILEGES;" >> wp_mariadb_config.sql
sudo systemctl restart nginx
sudo systemctl restart mariadb

# Password is required here
sudo mysql -u root -p"nasp19" < wp_mariadb_config.sql

sudo yum install -y wget rsync

# Alternatively curl -L
sudo wget http://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz
sudo cp wordpress/wp-config-sample.php wordpress/wp-config.php

sudo sed -i 's/database_name_here/wordpress/g' wordpress/wp-config.php
sudo sed -i 's/username_here/wordpress_user/g' wordpress/wp-config.php
sudo sed -i 's/password_here/nasp19/g' wordpress/wp-config.php

sudo sudo rsync -avP wordpress/ /usr/share/nginx/html/
sudo sudo mkdir /usr/share/nginx/html/wp-content/uploads

# Change ownership
sudo chown -R admin:nginx /usr/share/nginx/html/*

