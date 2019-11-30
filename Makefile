TAG=docker.home.spike.cx/sftp-access

all: build push

build: .PHONY
	docker build --tag $(TAG) .

push: .PHONY
	docker push $(TAG)

run: .PHONY
	docker run -ti -v "$(PWD)/users.txt:/users.txt" -p 2222:22 $(TAG)

.PHONY:
