#!/bin.sh

# !!! THIS PART IS RESPONSIBLE FOR CREATING THE DATABASE AND ITS USER !!!
# The database must be available before we can continue with the following steps
# Wait for MySQL server to be available
while ! mysqladmin ping -h"${MYSQL_HOST}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; do
	echo "Waiting for MySQL server to start..."
	sleep 2
done

# Using conditional here to avoid executing the following steps if the database already exists
if ! mysql -h ${MYSQL_HOST} -u root -p${MYSQL_ROOT_PASSWORD} -e "USE ${MYSQL_DATABASE};" > /dev/null 2>&1; then
	echo "Creating WordPress database..."
	echo "host: ${MYSQL_HOST}, user: ${MYSQL_USER}, password: ${MYSQL_PASSWORD}, database: ${MYSQL_DATABASE}, root password: ${MYSQL_ROOT_PASSWORD}"

	echo "Creating WordPress database: ${MYSQL_DATABASE} ..."
	mysql -h ${MYSQL_HOST} -u root -p${MYSQL_ROOT_PASSWORD} -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};"

	echo "Creating WordPress user: ${MYSQL_USER} ..."
	mysql -h ${MYSQL_HOST} -u root -p${MYSQL_ROOT_PASSWORD} -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"

	echo "Granting privileges to user: ${MYSQL_USER} ..."
	mysql -h ${MYSQL_HOST} -u root -p${MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';"

	echo "Flushing privileges..."
	# Flush the privileges to ensure they take effect
	mysql -h ${MYSQL_HOST} -u root -p${MYSQL_ROOT_PASSWORD} -e "FLUSH PRIVILEGES;"

fi 

#########################################################################

mkdir -p /var/www/html

cd /var/www/html

curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

chmod +x wp-cli.phar

mv wp-cli.phar /usr/local/bin/wp

wp core download --allow-root --path=/var/www/html/

wp config create --dbname="${MYSQL_DATABASE}" --dbuser="${MYSQL_USER}" --dbpass="${MYSQL_PASSWORD}" --dbhost="${MYSQL_HOST}" --allow-root --path=/var/www/html/
# wp core config --dbname="${MYSQL_DATABASE}" --dbuser="${MYSQL_USER}" --dbpass="${MYSQL_PASSWORD}" --dbhost="${MYSQL_HOST}" --allow-root --path=/var/www/html/

wp core install --url="${WP_URL}" --title="${WP_TITLE}" --admin_user="${WP_USER}" --admin_password="${WP_PASS}" --admin_email="${WP_EMAIL}" --allow-root --path=/var/www/html/

#########################################################################
# !!! THIS PART IS RESPONSIBLE FOR SETTING UP WORDPRESS AND ITS USER !!!

# The following commands is needed for PHP to be able to identify the host name, needed to generate URLs
# export HTTP_HOST="${WP_URL}"

# Check if `wp-config.php` file exists (this is the file that contains the database credentials)
# if [ ! -f /var/www/html/wp-config.php ]; then

# 	echo "Creating wp-config.php file..."
# 	wp config create --dbname="${MYSQL_DATABASE}" --dbuser="${MYSQL_USER}" --dbpass="${MYSQL_PASSWORD}" --dbhost="${MYSQL_HOST}" --allow-root --path=/var/www/html/
# else
# 	echo "wp-config.php file already exists."
# fi

# WordPress Core Install
echo "Checking for WordPress core install..."

if ! $(wp core is-installed --allow-root --path=/var/www/html/); then

	echo "Launching WordPress Core Install..."
	wp core install --url="${WP_URL}" --title="${WP_TITLE}" --admin_user="${WP_USER}" --admin_password="${WP_PASS}" --admin_email="${WP_EMAIL}" --allow-root --path=/var/www/html/
else
	echo "WordPress core already installed."
fi

#########################################################################

# PHP-FPM must be run as the main process in this container.
# And since we attempt to use the last version of PHP, the exact PHP-FPM 
# executable name and location may differ. So we need to find it first:

if [ -z "${PHP_FPM}" ]; then
	# Find the php-fpm executable
	PHP_FPM=$(find $(echo $PATH | tr ":" " ") -name "php-fpm*" -type f 2>/dev/null -print -quit)

	echo "php-fpm executable: $PHP_FPM"
fi

# Start php-fpm
# PHP_EXEC=&($PHP_FPM -F -R)
# echo "Starting php-fpm... status: [$PHP_EXEC]"
exec $PHP_FPM -F -R
