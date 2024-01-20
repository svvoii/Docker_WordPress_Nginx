# This will create a mariadb image with alpine as base image
FROM alpine:latest

RUN apk update && apk upgrade && apk add --no-cache \
	mariadb \
	mariadb-client

EXPOSE 3306

COPY ./db-setup.sh /tmp/db-setup.sh

ENTRYPOINT ["sh", "/tmp/db-setup.sh"]

CMD ["mariadbd", "--user=mysql"]
