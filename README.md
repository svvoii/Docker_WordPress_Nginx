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

