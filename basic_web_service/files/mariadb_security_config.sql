# Set root password
UPDATE mysql.user SET Password=PASSWORD('nasp19') WHERE User='root';

# Remove anonymous users
DELETE FROM mysql.user WHERE User='';

# Disallow remote root login
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

# Remove test database
DROP DATABASE test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\\_%';

## Wordpress Database Setup
CREATE DATABASE wordpress;
CREATE USER wordpress_user@localhost IDENTIFIED BY 'nasp19';
GRANT ALL PRIVILEGES ON wordpress.* TO wordpress_user@localhost;

# Reload privilege tables
FLUSH PRIVILEGES;