#!/bin.sh

# Find the php-fpm executable
PHP_FPM=$(find -f $(echo $PATH | tr ":" " ") -name "php-fpm*" -type f 2>/dev/null -print -quit)

# Start php-fpm
$PHP_FPM &

# Wait for WordPress to start
while ! mysqladmin ping -h"$MYSQL_HOST" --silent; do
	sleep 1
done

# BEFORE CREATING WP USER THE MYSQL DATABASE
# AND DB_USER MUST BE CREATED !!!

echo "Creating new WP user..."

# Check if the user already exists
if ! wp user get ${WP_USER} > /dev/null 2>&1; then
	# Create the user
	wp --allow-root user create ${WP_USER} ${WP_EMAIL} --role=administrator --user_pass=${WP_PASS} --path=/var/www/html/
fi

# Keep the container running
wait
