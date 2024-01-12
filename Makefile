# COLOR
MAGENTA=\033[0;35m
CYAN=\033[0;36m
RESET=\033[0m

pull:
	@echo "$(CYAN)Pulling images from Docker Hub...$(RESET)"
	docker compose pull

up:
	@echo "$(CYAN)Creating directories on the host...$(RESET)"
	@mkdir -p ./wordpress_data ./database_data
	@echo "$(CYAN)Creating custom volumes, network and starting containers...$(RESET)"
	docker compose up -d

down:
	@echo "$(CYAN)Stopping and removing containers...$(RESET)"
	docker compose down

restart: down up

clean_vol: down
	@echo "$(RED)Removing all volumes...$(RESET)"
	@if [ $$(docker volume ls -q | wc -l) -ne 0 ]; then docker volume rm $$(docker volume ls -q); fi

clean_all: clean_vol
	@echo "$(RED)Removing all images, volumes, networks and directories with data on the host...$(RESET)"
	@docker system prune --all --force
	sudo rm -rf ./wordpress_data ./database_data

ls:
	@echo "$(MAGENTA) -> Listing images...$(RESET)" && docker image ls
	@echo "$(MAGENTA) -> Listing running containers...$(RESET)" && docker ps
	@echo "$(MAGENTA) -> Listing volumes...$(RESET)" && docker volume ls
	@echo "$(MAGENTA) -> Listing networks...$(RESET)" && docker network ls | awk '$$2 !~ /^(bridge|host|none)$$/'

logs:
	@echo "$(MAGENTA)Showing logs...$(RESET)"
	docker compose logs -f
