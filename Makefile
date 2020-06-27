TAG=docker.home.spike.cx/sftp-access

all: build push

build: .PHONY
	docker build --tag $(TAG) .

push: .PHONY
	docker push $(TAG)

run: .PHONY
	docker run -ti \
		--name "sftp-test" \
		-v "$(PWD)/users.txt:/users.txt" \
		-v "/home/spike/Downloads:/mounts/downloads" \
		-v "$(PWD)/home:/home" \
		-v "$(PWD)/data:/data" \
		-p 2222:22 \
		$(TAG)

.PHONY:
