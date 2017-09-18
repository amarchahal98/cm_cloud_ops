echo "UPDATE mysql.user SET Password=PASSWORD('nasp19') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\\_%';
CREATE DATABASE wordpress;
CREATE USER wordpress_user@localhost IDENTIFIED BY 'nasp19';
GRANT ALL PRIVILEGES ON wordpress.* TO wordpress_user@localhost;
FLUSH PRIVILEGES;" > mariadb_security_config.sql



sudo mysql -u root < mariadb_security_config.sql

