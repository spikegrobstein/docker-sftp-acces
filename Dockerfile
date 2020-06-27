FROM ubuntu:20.04

RUN apt update \
      && apt install -y \
        bash \
        curl \
        openssh-sftp-server \
        openssh-server

COPY files/sshd_config /etc/ssh/sshd_config
COPY files/create_users.bash /create_users

RUN mkdir -p /run/sshd /ssh-keys \
      && touch /users.txt \
      && chmod +x /create_users \
      && mv /etc/ssh/ssh_host_*key /ssh-keys/

EXPOSE 22
VOLUME /ssh-keys

CMD [ "/create_users" ]
