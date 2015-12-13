.PHONY: all help build run builddocker rundocker kill rm-image rm clean enter logs

user = $(shell whoami)
ifeq ($(user),root)
$(error  "do not run as root! run 'gpasswd -a USER docker' on the user of your choice")
endif

all: help

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""  This is merely a base image for usage read the README file
	@echo ""   1. make run       - build and run docker container
	@echo ""   2. make build     - build docker container
	@echo ""   3. make clean     - kill and remove docker container
	@echo ""   4. make enter     - execute an interactive bash in docker container
	@echo ""   3. make logs      - follow the logs of docker container

build: NAME TAG VOLUME id_rsa.pub builddocker

run: build rundocker

init: build initdocker

rundocker:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval VOLUME := $(shell cat VOLUME))
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	$(eval NET := $(shell cat NET))
	$(eval UID := $(shell id -u))
	chmod 777 $(TMP)
	@docker create --name=$(NAME) \
	--cidfile="cid" \
	-e "DOCKER_UID=$(UID)" \
	-v $(TMP):/tmp \
	-v $(VOLUME)/civicrm:/var/www/civicrm \
	-v $(VOLUME)/mysql:/var/lib/mysql \
	-p  2222:22 \
	$(NET) \
	-p  8001-8100:8001-8100 \
	-v /var/run/docker.sock:/run/docker.sock \
	-v $(shell which docker):/bin/docker \
	-t $(TAG)
	docker start $(TAG)

initdocker:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	$(eval UID := $(shell id -u))
	chmod 777 $(TMP)
	@docker create --name=$(NAME) \
	--cidfile="cid" \
	-e "DOCKER_UID=$(UID)" \
	-v $(TMP):/tmp \
	-p  2222:22 \
	-p  8001-8100:8001-8100 \
	-v /var/run/docker.sock:/run/docker.sock \
	-v $(shell which docker):/bin/docker \
	-t $(TAG)
	docker start $(TAG)

id_rsa.pub:
	cp ~/.ssh/id_rsa.pub ./

builddocker:
	/usr/bin/time -v docker build -t `cat TAG` .

kill:
	-@docker kill `cat cid`

rm-image:
	-@docker rm `cat cid`
	-@rm cid

rm: kill rm-image

clean: rm

enter:
	docker exec -i -t `cat cid` /bin/bash

logs:
	docker logs -f `cat cid`

# sudo on the cp as I am getting errors on btrfs storage driven docker systems

grab:
	-mkdir -p datadir
	sudo docker cp `cat cid`:/var/www/civicrm datadir/
	sudo docker cp `cat cid`:/var/lib/mysql datadir/
	sudo chown -R $(user). datadir/mysql
	echo `pwd`/datadir > VOLUME

NAME:
	@while [ -z "$$NAME" ]; do \
		read -r -p "Enter the name you wish to associate with this container [NAME]: " NAME; echo "$$NAME">>NAME; cat NAME; \
	done ;

TAG:
	@while [ -z "$$TAG" ]; do \
		read -r -p "Enter the tag you wish to associate with this container [TAG]: " TAG; echo "$$TAG">>TAG; cat TAG; \
	done ;

VOLUME:
	@while [ -z "$$VOLUME" ]; do \
		read -r -p "Enter the volume you wish to associate with this container [VOLUME]: " VOLUME; echo "$$VOLUME">>VOLUME; cat VOLUME; \
	done ;
