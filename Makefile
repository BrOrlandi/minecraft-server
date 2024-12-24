server = ubuntu@brorlandi.xyz
project_path = $(shell basename $(shell pwd))

rsync:
	rsync -azv . $(server):$(project_path) --exclude-from=.gitignore

deploy: rsync
	ssh $(server) "cd $(project_path) && docker-compose up -d --build"

down:
	ssh $(server) "cd $(project_path) && docker-compose down"