# This will create a mariadb image with alpine as base image
FROM alpine:latest

RUN apk update && apk add \
	mariadb \
	mariadb-client

COPY ./my.cnf /etc/mysql/my.cnf

CMD ["mysqld"]
