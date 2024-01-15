FROM alpine:latest

# Adding "edge" repository for lapest php version
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories

# Create www-data user and group if they don't exist
RUN addgroup -g 82 -S www-data 2>/dev/null || true \
	&& adduser -u 82 -D -S -G www-data www-data 2>/dev/null || true

# Installing mysql-client
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

# Copying php-fpm config files
COPY ./www.conf /etc/php7/php-fpm.d/www.conf
COPY ./php-fpm.conf /etc/php7/php-fpm.conf

RUN mkdir -p /var/www/html

COPY ./wp-config.php /var/www/html/wp-config.php

# Downloading WordPress
RUN curl -O https://wordpress.org/latest.tar.gz \
	&& tar -xzvf latest.tar.gz -C /var/www/html --strip-components=1 \
	&& rm latest.tar.gz

RUN chown -R www-data:www-data /var/www/html

# Installing wp-cli
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x wp-cli.phar \
	&& mv wp-cli.phar /usr/bin/wp

COPY ./wp-config.php /tmp/wp-config.php

COPY ./new-wp-user.sh /tmp/new-wp-user.sh
RUN chmod +x /tmp/new-wp-user.sh

CMD ["sh", "/tmp/new-wp-user.sh"]
