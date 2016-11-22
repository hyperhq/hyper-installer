FROM fedora:23
MAINTAINER Jimmy Xu <jimmy@hyper.sh>

RUN  dnf -y install wget curl git vim tar ca-certificates \
     && dnf clean all

WORKDIR /hyper-installer
