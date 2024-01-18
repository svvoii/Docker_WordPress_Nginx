#!/bin/sh
echo "Starting db-setup.sh script..."

if [ ! -d "/run/mysqld" ]; then
	mkdir -p /run/mysqld
	chown -R mysql:mysql /run/mysqld
fi

if [ ! -d "/var/lib/mysql/mysql" ]; then

	chown -R mysql:mysql /var/lib/mysql
 
	echo "Database namne: ${MYSQL_DATABASE}"
	echo "Database user: ${MYSQL_USER}"
	echo "Database password: ${MYSQL_PASSWORD}"
	echo "Database root password: ${MYSQL_ROOT_PASSWORD}"

	echo "Initializing database..."

	mysql_install_db --basedir=/usr --datadir=/var/lib/mysql --user=mysql --skip-test-db --rpm 
	
	tmp_file=`mktemp`
	if [ ! -f "$tmp_file" ]; then
		echo "Failed to create temporary file"
		exit 1
	fi

	cat << EOF > $tmp_file
USE mysql;
FLUSH PRIVILEGES;

DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE} DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';

FLUSH PRIVILEGES;
EOF

	echo "Running mysqld --bootstrap..."
	/usr/bin/mysqld --user=root --bootstrap < $tmp_file
	if [ $? -ne 0 ]; then
		echo "Failed to initialize database"
		exit 1
	fi
	rm -f $tmp_file

else
	echo "Database already initialized..."
fi
# Allowing remote connections
sed -i "s|skip-networking|# skip-networking|g" /etc/my.cnf.d/mariadb-server.cnf
sed -i "s|.*bind-address\s*=.*|bind-address=0.0.0.0|g" /etc/my.cnf.d/mariadb-server.cnf

# Starting MariaDB
exec /usr/bin/mysqld --user=mysql --console
