# This will create a mariadb image with alpine as base image
FROM alpine:latest

RUN apk update && apk add \
	mariadb \
	mariadb-client

COPY ./db-setup.sh /tmp/db-setup.sh

#CMD ["mysqld"]
ENTRYPOINT ["sh", "/tmp/db-setup.sh"]
