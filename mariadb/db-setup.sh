#!/bin/sh
echo "Starting db-setup.sh script..."

# Preparing mariadb for installation
if [ ! -d "/var/lib/mysql/mysql" ]; then

	# echo "Creating /run/mysqld and /var/lib/mysql directories..."
	mkdir -p /run/mysqld /var/lib/mysql
	chown -R mysql:mysql /var/lib/mysql /run/mysqld

	# echo "Setting up mariadb config, network and access..."
	sed -i 's/skip-networking/# skip-networking/g' /etc/my.cnf.d/mariadb-server.cnf
	sed -i 's/#bind-address=0.0.0.0/bind-address=0.0.0.0/g' /etc/my.cnf.d/mariadb-server.cnf

	#echo "Installing mariadb base..."
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db
else
	echo "MariaDB is already installed..."
fi

# Setting up mariadb root password, creating database and user
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then 

	cat << EOF > /tmp/setup.sql
		USE mysql;
		FLUSH PRIVILEGES;
		DELETE FROM mysql.user WHERE User='';
		DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
		CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE} DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
		GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
		FLUSH PRIVILEGES;
EOF

	mariadbd --user=mysql --bootstrap < /tmp/setup.sql
	rm -rf /tmp/setup.sql

	echo "Database setup is done..."
else
	echo "Database already exists..."	
fi

exec "$@"
