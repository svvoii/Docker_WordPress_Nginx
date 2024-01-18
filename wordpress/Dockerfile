FROM alpine:latest

# Adding "edge" repository for the latest php version
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories

# Installing mysql-client and latest php-fpm version (currently 8.2)
RUN apk update && apk add --no-cache \
	curl \
	mysql-client \
	php \
	php-fpm \
	php-mysqli \
	php-gd \
	php-curl \
	php-zip \
	php-xml \
	php-mbstring \
	php-json \
	php-intl \
	php-dom \
	php-phar

# Copying the `php-fpm.conf` and `www.conf` files to the appropriate location
# !!! The directory might be different depending on the PHP version !!!
# COPY ./www.conf /etc/php7/php-fpm.d/www.conf
# COPY ./php-fpm.conf /etc/php7/php-fpm.conf
COPY ./php-fpm.conf /etc/php82/php-fpm.conf
COPY ./www.conf /etc/php82/php-fpm.d/www.conf

# Copying the script that will download, install and configure WordPress
COPY ./wp-setup.sh /tmp/wp-setup.sh
RUN chmod +x /tmp/wp-setup.sh

ENTRYPOINT ["sh", "/tmp/wp-setup.sh"]
