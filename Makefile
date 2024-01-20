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
	@echo "  build        Builds custom docker images"
	@echo "  up           Create directories on the host, create custom volumes, network and starting containers"
	@echo "  down         Stopping and removing running containers"
	@echo "  clean-all    Bringd down all containers, removes all volumes and directories with data on the host"
	@echo "  rebuild      Executes 'clean_all' and builds fresh images"
	@echo "  ls           Lists images, containers, volumes and networks"
	@echo "  log-1        Showing logs for ${DB}"
	@echo "  log-2        Showing logs for ${WP}"
	@echo "  log-3        Showing logs for ${NGX}"
	@echo "  logs         Showing all logs"

build:
	@echo "$(CYAN)Creating empty directories on the host...$(RESET)"
	@mkdir -p ./wordpress_data ./database_data
	@echo "$(CYAN)Building images...$(RESET)"
	docker compose build

up:
	@echo "$(CYAN)Creating custom volumes, network and starting containers...$(RESET)"
	docker compose up -d

down:
	@echo "$(CYAN)Stopping and removing containers and networks...$(RESET)"
	docker compose down
	docker container prune --force

clean-all: down
	@echo "$(RED)Removing all volumes and directories with data on the host...$(RESET)"
	@if [ $$(docker volume ls -q | wc -l) -ne 0 ]; then docker volume rm $$(docker volume ls -q); fi
	sudo rm -rf ./wordpress_data ./database_data
	@echo "$(RED)Removing all images...$(RESET)"
	docker rmi $$(docker images -q) --force

rebuild: clean_all build

ls:
	@echo "$(MAGENTA) -> Listing images...$(RESET)" && docker image ls
	@echo "$(MAGENTA) -> Listing running containers...$(RESET)" && docker ps -a
	@echo "$(MAGENTA) -> Listing volumes...$(RESET)" && docker volume ls
	@echo "$(MAGENTA) -> Listing networks...$(RESET)" && docker network ls | awk '$$2 !~ /^(bridge|host|none)$$/'

log-1:
	@echo "$(MAGENTA)Showing logs for ${DB}...$(RESET)"
	docker compose logs ${DB}	

log-2:
	@echo "$(MAGENTA)Showing logs for ${WP}...$(RESET)"
	docker compose logs ${WP}

log-3:
	@echo "$(MAGENTA)Showing logs for ${NGX}...$(RESET)"
	docker compose logs ${NGX}

logs:
	@echo "$(MAGENTA)Showing logs from all containers...$(RESET)"
	docker compose logs

.PHONY: help build up down clean_all rebuild ls log_1 log_2 log_3 logs
