# Docker Wordpress Nginx Setup

### Description

This repo contains a docker-compose file that will set up a wordpress site with nginx and mysql as separate services/containers.  
This README will explain the steps of the set up for educational purposes.   
The images used are the official images from docker hub. The main purpose is to show how these services can be set up and how they interact with each other.  
`nginx` is used to serve the static files and to reverse proxy the requests to the wordpress container.  
`wordpress` is used to serve, ctraete and manage the wordpress site.
`mysql` is used to store the data of the wordpress site.
`phpmyadmin` (as a part of wordpress container) is used to manage the mysql database.

### 1. Basic Set Up
```yaml
version: '3.9'

services:
  # Webserver
  nginx:
    image: nginx:stable-alpine
    container_name: nginx-server
    ports:
      - 80:80

  # Database
  mysql:
    image: mysql:latest
    container_name: mysql-db
    env_file:
      - .env

  # Backend
  php:
    image: php:7.4-fpm-alpine
    container_name: php-fpm
```  
This is the basic set up of the docker-compose file. By running `docker-compose up -d` the containers will be created and started.  
`make up` is used to run the docker-compose command.  
By visiting `http://localhost` the nginx welcome page shall be displayed. At this point the webserver portion of the set up shall be considered as working.

#################################################

### 2. Adding Wordpress and PHP-FPM (from Docker hub) in one separate container  

```yaml
version: '3.9'

services:
  # Webserver
  nginx:
    image: nginx:stable-alpine
    container_name: nginx-server
    depends_on:
      - wordpress
    ports:
      - 80:80
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
      - wordpress:/var/www/html
    networks:
      - wordpress_network
    restart: always

  # Database
  mysql:
    image: mysql:latest
    container_name: mysql-db
    env_file:
      - .env
    volumes:
      - database:/var/lib/mysql
    networks:
      - wordpress_network
    restart: always

  # Wordpress + PHP-FPM 8.2 on Alpine
  wordpress:
    image: wordpress:fpm-alpine
    container_name: wordpress-alpine
    depends_on:
      - mysql
    env_file:
      - .env
    volumes:
      - wordpress:/var/www/html
    networks:
      - wordpress_network
    restart: always

volumes:
  wordpress:
    driver: local
    name: wordpress_data_volume
    driver_opts:
      type: none
      o: bind
      device: ./wordpress_data

  database:
    driver: local
    name: database_data_volume
    driver_opts:
      type: none
      o: bind
      device: ./database_data
  
networks:
   wordpress_network:
     name: wordpress_network
     driver: bridge

```

In this step the wordpress and php-fpm are added in one container. In this step the wordpress files shall appear in the `wordpress_data` folder at the root of this repo.  
The `wordpress_data` folder is also shared with the nginx container.  
In order to make this work, so the nginx container can serve the wordpress files, the `default.conf` file is added in the `nginx` folder.:  

```nginx
# default.conf
upstream php {
	server wordpress-alpine:9000;
}

server {
	listen 80;
	server_name localhost custom-domain-name;

	root /var/www/html;

	index index.php index.html index.htm;

	error_log /var/log/nginx/error.log;
	access_log /var/log/nginx/access.log;

	location / {
		try_files $uri $uri/ /index.php?$args;
	}

	location ~ \.php$ {
		fastcgi_split_path_info ^(.+\.php)(/.+)$;
		fastcgi_pass php;
		fastcgi_index index.php;
		include fastcgi_params;
		fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
		fastcgi_param SCRIPT_NAME $fastcgi_script_name;
	}
}
```  

The `default.conf` file is copied in the nginx container in the `/etc/nginx/conf.d/` folder.

Also, the custom network `wordpress_network` is created to allow the containers to communicate with each other. Being on the same network it is not necessary to expose the ports for internetwork communication between containers. Only the nginx port 80 is exposed to the host machine for access from the browser.    

The `database_data` folder is also created at the root of the repo to store the data of the mysql container.  

`make up` will create and start the containers based on the `docker-compose.yaml` above. So `http://localhost` shall display the wordpress installation page. You can use custom `http://custom-domain-name` by specifying/adding `server_name` in `default.conf` and by adding the domain name in the `/etc/hosts` file as `127.0.0.1 custom-domain-name`.  

Since the `.env` was used in `wordpress` we can proceed with the installation of wordpress. By choosing the language and clicking `Continue` it will then ask for the database credentials. Here we can use the credentials from the `.env` file:
```bash
MYSQL_DATABASE=wordpress_db
MYSQL_USER=wp_user
MYSQL_PASSWORD=wp_pass
# and the database host should be the name of the mysql container (line 22 in above docker-compose.yaml): `mysql-db`
```
Once the database credentials are entered, the `wp-config.php` file will be created (must appear inside `wordpress_data` directory) and the installation can be completed.  

In the next step of the installation, the site title, username, password and email will be asked. Once these are entered, the installation is complete and the wordpress site is ready to be used.  
At this point the `Welcome to WordPress` page and the dashboard shall be displayed.

#################################################

### 3. Modifying the wordpress container to build a custom image and setting it up with the script `wp-setup.sh`  

Also changing the database to `mariadb` (official image) which is a bit lighter than `mysql`.

This is the version of docker compose file that will build and use a custom image for wordpress.  
```yaml
version: '3.9'

services:
  # Webserver
  nginx:
    image: nginx:stable-alpine
    container_name: nginx-server
    depends_on:
      - wordpress
    ports:
      - 80:80
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
      - wordpress:/var/www/html
    networks:
      - wordpress_network
    restart: always

  # Database
  mariadb:
    container_name: database
    image: mariadb:latest
    env_file:
      - .env
    volumes:
      - database:/var/lib/mysql
    networks:
      - wordpress_network
    restart: always

  # Wordpress + PHP-FPM 8.2 on Alpine
  wordpress:
    container_name: wordpress-alpine
    build: ./wordpress
    image: wordpress:custom
    depends_on:
      - mariadb
    env_file:
      - .env
    volumes:
      - wordpress:/var/www/html
    networks:
      - wordpress_network
    restart: always

volumes:
  wordpress:
    driver: local
    name: wordpress_data_volume
    driver_opts:
      type: none
      o: bind
      device: ./wordpress_data

  database:
    driver: local
    name: database_data_volume
    driver_opts:
      type: none
      o: bind
      device: ./database_data
  
networks:
   wordpress_network:
     name: wordpress_network
     driver: bridge
```
The Docker file and supportive files for PHP setup are in the `wordpress` folder.  

```dockerfile
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

```  

The latest version of PHP_FPM is used (8.2) and configured.  
The `wp-setup.sh` script is used to download, install and configure the latest version of wordpress:  

```bash
#!/bin.sh
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

```  
  
### 4. Customizing the database container.  

Setting up MariaDB in a custom image. This is mainly done for educational purposes and will allow us to better understand how the database shall be set up and how it interacts with the wordpress container.  
The custom image is based on `alpine:latest` official image. It will also be a slightly lighter than the official `mariadb` image.  

```dockerfile
# This will create a mariadb image with alpine as base image
FROM alpine:latest

RUN apk update && apk upgrade && apk add --no-cache \
	mariadb \
	mariadb-client

EXPOSE 3306

COPY ./db-setup.sh /tmp/db-setup.sh

ENTRYPOINT ["sh", "/tmp/db-setup.sh"]

CMD ["mariadbd", "--user=mysql"]

```
The heart of the setu is the `db-setup.sh` script.  

```bash
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
```

The `db-setup.sh` script is responsible for setting up the database. The evironment variables, used in the script, are defined in the `.env` file and passed to the containers `mariadb` and `wordpress` in the `docker-compose.yaml` file.  

```yaml
version: '3.9'

services:
  # Webserver
  nginx:
    image: nginx:stable-alpine
    container_name: nginx-server
    depends_on:
      - wordpress
    ports:
      - 80:80
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
      - wordpress:/var/www/html
    networks:
      - wordpress_network
    restart: always

  # Database
  mariadb:
    container_name: database
    build: ./mariadb
    image: mariadb:custom
    env_file:
      - .env
    volumes:
      - database:/var/lib/mysql
    networks:
      - wordpress_network
    restart: always

  # Wordpress + PHP-FPM 8.2 on Alpine
  wordpress:
    container_name: wordpress-alpine
    build: ./wordpress
    image: wordpress:custom
    depends_on:
      - mariadb
    env_file:
      - .env
    volumes:
      - wordpress:/var/www/html
    networks:
      - wordpress_network
    restart: always

volumes:
  wordpress:
    driver: local
    name: wordpress_data_volume
    driver_opts:
      type: none
      o: bind
      device: ./wordpress_data

  database:
    driver: local
    name: database_data_volume
    driver_opts:
      type: none
      o: bind
      device: ./database_data
  
networks:
   wordpress_network:
     name: wordpress_network
     driver: bridge

```

The next step will be to customize the `nginx` container.  

### 5. Customizing the nginx container.  

The nginx container will be customized to serve the static files and to reverse proxy the requests to the wordpress container only, including `/wp-admin`, `/wp-login.php`, `/phpmyadmin`.

```Dockefile
# This will build the NGINX custom image
FROM alpine:latest

RUN apk update && apk upgrade && apk add --no-cache \
	nginx \
	openssl

RUN mkdir -p /etc/nginx/ssl /run/nginx

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-subj "/C=FR/ST=IDF/L=Paris/O=42Paris/OU=sbocanci/CN=sbocanci.42.fr" \
	-keyout /etc/nginx/ssl/sbocanci.42.fr.key \
	-out /etc/nginx/ssl/sbocanci.42.fr.crt

COPY ./nginx.conf /etc/nginx/nginx.conf

ENTRYPOINT ["nginx", "-g", "daemon off;"]

```  
The `openssl` command is used to generate a self-signed certificate to allow `https` connection. The browser will display a warning that the certificate is not trusted because of its self-signed nature.  

The following `nginx.conf` file is copied in the nginx container in the `/etc/nginx/` folder.  


```nginx
events {
	worker_connections  1024;
}

http {
	
	server {

		listen 80;
		listen [::]:80 default_server;

		server_name localhost sbocanci.42.fr;
		return 301 https://$server_name$request_uri;
	}

	server {

		listen 443 ssl default_server;
		listen [::]:443 ssl default_server;

		server_name localhost sbocanci.42.fr;
		root /var/www/html;
		index index.php index.html index.htm;

		error_log /var/log/nginx/error.log;
		access_log /var/log/nginx/access.log;

		location / {
			try_files $uri $uri/ /index.php?$args;
		}

		location ~ \.php$ {
			fastcgi_pass wordpress-alpine:9000;
			try_files $uri =404;
			fastcgi_split_path_info ^(.+\.php)(/.+)$;
			fastcgi_index index.php;
			include fastcgi_params;
			fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
			fastcgi_param SCRIPT_NAME $fastcgi_script_name;
		}

		ssl_protocols TLSv1.2 TLSv1.3;
		ssl_certificate /etc/nginx/ssl/sbocanci.42.fr.crt;
		ssl_certificate_key /etc/nginx/ssl/sbocanci.42.fr.key;
	}
}
```
