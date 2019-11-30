TAG=docker.home.spike.cx/sftp-access

all: build push

build: .PHONY
	docker build --tag $(TAG) .

push: .PHONY
	docker push $(TAG)

run: .PHONY
	docker run -ti \
		--cap-add=SYS_ADMIN \
		-v "$(PWD)/users.txt:/users.txt" \
		-v "$(PWD)/mounts:/mounts:ro" \
		-p 2222:22 \
		$(TAG)

.PHONY:
