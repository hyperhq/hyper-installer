FROM fedora:24
MAINTAINER Jimmy Xu <jimmy@hyper.sh>

RUN  dnf -y install wget curl git vim tar ca-certificates \
     && dnf clean all

#patch
RUN dnf -y install glibc-locale-source && dnf clean all
COPY etc/enviroment /etc/enviroment

WORKDIR /hyper-installer
