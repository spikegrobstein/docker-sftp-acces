FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive
RUN apt update \
      && apt install -y \
        bash \
        curl \
        openssh-sftp-server \
        openssh-server \
        moreutils

COPY files/sshd_config /etc/ssh/sshd_config
COPY files/sftpctl /usr/bin/sftpctl
COPY files/data /data
COPY files/adduser.conf /etc/adduser.conf
COPY files/motd /etc/motd

RUN mkdir -p /run/sshd \
      && touch /users.txt \
      && chmod +x /usr/bin/sftpctl \
      && umask 0066 \
      && rm -rf \
          /etc/skel/.bash* \
          /etc/skel/.profile \
          /etc/update-motd.d/

EXPOSE 22
VOLUME /ssh-keys
VOLUME /home
VOLUME /data

CMD [ "sftpctl", "init" ]
