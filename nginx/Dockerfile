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

# mkcert toot.. requires installation of `mkcert` on the host `https://github.com/FiloSottile/mkcert`
# ADD ./certs /etc/nginx/ssl/self-signed

ENTRYPOINT ["nginx", "-g", "daemon off;"]
