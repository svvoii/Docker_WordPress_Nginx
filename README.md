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

### 2. Adding Wordpress and PHP-FPM in one separate container  

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
upstream php {
	server unix:/tmp/php-cgi.socket;
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
		fastcgi_pass wordpress-alpine:9000;
		fastcgi_index index.php;
		include fastcgi_params;
		fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
		fastcgi_param SCRIPT_NAME $fastcgi_script_name;
	}
}
```  

The `default.conf` file is copied in the nginx container in the `/etc/nginx/conf.d/` folder.

Also, the custom network `wordpress_network` is created to allow the containers to communicate with each other, being on the same network.  
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


