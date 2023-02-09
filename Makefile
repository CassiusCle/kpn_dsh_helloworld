PLATFORM=poc
TENANT=training
DOCKER_REPO_URL=registry.cp.kpn-dsh.com/$(TENANT)
VERSION=1
tagname=hello-world
tenantuserid=1054
image=$(DOCKER_REPO_URL)/$(tagname):$(VERSION)

help:
	@echo "login   - login to the relevant repository"
	@echo "fix     - run dos2unix on every file"
	@echo "build   - build the image"
	@echo "rebuild - build the image with the --no-cache flag"
	@echo "itgo    - shorthand for fix, build, push, show"
	@echo "run     - run the image in local docker"
	@echo "push    - push the  image to jfrog"
	@echo "show    - show the current make variables"
login:
	docker login $(DOCKER_REPO_URL)
fix: 
	find . -type f -print0 | xargs -0 dos2unix
build:
	docker build -t $(tagname) -f Dockerfile --build-arg tenantuserid=$(tenantuserid) .
	docker tag  $(tagname) $(image)
rebuild:
	docker build --no-cache -t $(tagname) -f Dockerfile --build-arg tenantuserid=$(tenantuserid) .
	docker tag  $(tagname) $(image)
all:
	make build
	make push
	make show
run:
	docker run -u $(tenantuserid):$(tenantuserid) -it --entrypoint "/bin/sh" $(image)
fun:
	curl -H "Accept: application/json" https://icanhazdadjoke.com/
push:
	docker push $(image)
show:
	@echo "#make file configuration"
	@echo "#URL          :" $(DOCKER_REPO_URL)
	@echo "#PLATFORM     :" $(PLATFORM)
	@echo "#TENANT       :" $(TENANT)
	@echo "#tenantuserid :" $(tenantuserid)
	@echo "#tagname      :" $(tagname)
	@echo "#version      :" $(VERSION)
	@echo "#image        :" $(image)
