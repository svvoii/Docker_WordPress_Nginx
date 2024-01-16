# COLOR
MAGENTA=\033[0;35m
CYAN=\033[0;36m
RED=\033[0;31m
RESET=\033[0m

# Services
DB=mariadb
WP=wordpress
NGX=nginx

help:
	@echo "$(CYAN)Usage:$(RESET)"
	@echo "  make [command]"
	@echo
	@echo "$(CYAN)Available Commands:$(RESET)"
	@echo "  build        Builds custom or/and pulls images from Docker Hub"
	@echo "  up           Create directories on the host, create custom volumes, network and starting containers"
	@echo "  down         Stopping and removing containers"
	@echo "  restart      down + up"
	@echo "  clean_vol    down + Removing all volumes"
	@echo "  clean_all    clean_vol + Removing all images, volumes, networks and directories with data on the host"
	@echo "  ls           Listing images, running containers, volumes and networks"
	@echo "  logs         Showing logs"

build:
	@echo "$(CYAN)Creating empty directories on the host...$(RESET)"
	@mkdir -p ./wordpress_data ./database_data
	@echo "$(CYAN)Building images...$(RESET)"
	docker compose build ${WP}
	@echo "$(CYAN)Pulling images from Docker Hub...$(RESET)"
	docker compose pull ${DB} ${NGX}

up:
#	@echo "$(CYAN)Creating empty directories on the host...$(RESET)"
#	@mkdir -p ./wordpress_data ./database_data
	@echo "$(CYAN)Creating custom volumes, network and starting containers...$(RESET)"
	docker compose up -d

down:
	@echo "$(CYAN)Stopping and removing containers...$(RESET)"
	docker compose down
	docker container prune --force

restart: down up

clean_vol: down
	@echo "$(RED)Removing all volumes and directories with data on the host...$(RESET)"
	@if [ $$(docker volume ls -q | wc -l) -ne 0 ]; then docker volume rm $$(docker volume ls -q); fi
	sudo rm -rf ./wordpress_data ./database_data

clean_img: down
	@echo "$(RED)Removing all images...$(RESET)"
	docker rmi $$(docker images -q) --force

clean_net: down
	@echo "$(RED)Removing all networks...$(RESET)"
	docker network prune --force
	docker builder prune --all --force

clean_all: clean_vol clean_img clean_net
	@echo "$(RED)Removing all images, volumes, networks and directories with data on the host...$(RESET)"

ls:
	@echo "$(MAGENTA) -> Listing images...$(RESET)" && docker image ls
	@echo "$(MAGENTA) -> Listing running containers...$(RESET)" && docker ps
	@echo "$(MAGENTA) -> Listing volumes...$(RESET)" && docker volume ls
	@echo "$(MAGENTA) -> Listing networks...$(RESET)" && docker network ls | awk '$$2 !~ /^(bridge|host|none)$$/'

logs:
	@echo "$(MAGENTA)Showing logs...$(RESET)"
	docker compose logs -f
