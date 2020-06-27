FROM ubuntu:20.04

RUN apt update \
      && apt install -y \
        bash \
        curl \
        openssh-sftp-server \
        openssh-server

COPY files/sshd_config /etc/ssh/sshd_config
COPY files/sftpctl /usr/bin/sftpctl
COPY files/data /data

RUN mkdir -p /run/sshd /ssh-keys \
      && touch /users.txt \
      && chmod +x /usr/bin/sftpctl \
      && mv /etc/ssh/ssh_host_*key /ssh-keys/

EXPOSE 22
VOLUME /ssh-keys
VOLUME /home
VOLUME /data

CMD [ "sftpctl", "init" ]
