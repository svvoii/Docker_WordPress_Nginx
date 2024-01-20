#!/bin/sh
echo "Starting wp-setup.sh script..."

# The database container must be available before continuing with the wp setup
# Waiting for proper database to be created in the database container
while ! mysql -h"${MYSQL_HOST}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -D"${MYSQL_DATABASE}" 2>/dev/null; do
	echo "Waiting for MySQL server to start..."
	sleep 2
done

echo "MySQL server is up and running.."

#########################################################################

# !!! THIS PART IS RESPONSIBLE FOR SETTING UP WORDPRESS, WORDPRESS DATABASE, ITS USER AND WP USER ITSELF !!!
# The `if` statement below is needed to avoid executing the following steps when the container is restarted
if ! $(wp core is-installed --allow-root --path=/var/www/html/); then

	# Both [www-data] user and [www-data] group must be present for php-fpm to run as non-root user 
	addgroup -g 82 -s www-data 2>/dev/null
	adduser -u 82 -D -S -G www-data www-data

	echo "Installing WordPress..."

	# Creating the directory where WordPress files (website) will be installed
	mkdir -p /var/www/html
	cd /var/www/html

	# Downloading `wp-cli` (WordPress Command Line Interface) tool to manage manual WordPress installation
	curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	chmod +x wp-cli.phar
	mv wp-cli.phar /usr/local/bin/wp

	# Downloading WordPress files
	wp core download --allow-root --path=/var/www/html/

	# Creating `wp-config.php` file (this is the file that contains the database credentials)
	wp config create --dbname="${MYSQL_DATABASE}" --dbuser="${MYSQL_USER}" --dbpass="${MYSQL_PASSWORD}" --dbhost="${MYSQL_HOST}" --allow-root --path=/var/www/html/

	# WordPress Core Install. This will create the WordPress user/pass to access the admin panel at `http://localhost/wp-admin/`
	wp core install --url="${WP_URL}" --title="${WP_TITLE}" --admin_user="${WP_USER}" --admin_password="${WP_PASS}" --admin_email="${WP_EMAIL}" --skip-email --allow-root --path=/var/www/html/

else
	echo "WordPress installed and configured."
fi

#########################################################################

# PHP-FPM must be run as the main process in this container.
# Since we use the latest version of PHP at the time, the exact PHP-FPM 
# executable name and location may differ. So we search for it first:

if [ -z "${PHP_FPM}" ]; then
	# Find the php-fpm executable
	PHP_FPM=$(find $(echo $PATH | tr ":" " ") -name "php-fpm*" -type f 2>/dev/null -print -quit)

	echo "php-fpm executable: $PHP_FPM"
fi

# Starting PHP-FPM in `-F` (foreground) mode (this is needed for the container to stay up and running):
echo "Starting php-fpm..."
exec $PHP_FPM -F
