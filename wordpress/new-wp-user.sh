#!/bin.sh

# Find the php-fpm executable
PHP_FPM=$(find $(echo $PATH | tr ":" " ") -name "php-fpm*" -type f 2>/dev/null -print -quit)

echo "php-fpm executable: $PHP_FPM"

# Start php-fpm
$PHP_FPM &

# The database must be available before we can continue with the following steps
# !!!

# Wait for database to be available
while ! mysql -h ${MYSQL_HOST} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} -e "use ${MYSQL_DATABASE}"; do
	echo "..waiting for "${MYSQL_DATABASE}" database to be created..."

#while ! mysqladmin ping -h"$MYSQL_HOST" --silent; do
#	echo "Waiting for MySQL to start..."
	sleep 1
done

echo "Creating new WP user..."

# Check if the user already exists
if ! wp user get ${WP_USER} > /dev/null 2>&1; then
	# Create the user
	wp --allow-root user create ${WP_USER} ${WP_EMAIL} --role=administrator --user_pass=${WP_PASS} --path=/var/www/html/
fi

# Keep the container running
wait
