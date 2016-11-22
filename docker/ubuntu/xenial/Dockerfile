FROM ubuntu:16.04
MAINTAINER Jimmy Xu <jimmy@hyper.sh>

ENV DEBIAN_FRONTEND noninteractive
COPY sources.list.xenial /etc/apt/sources.list

# install common package
RUN apt-get update && \
    apt-get install -y curl vim
#	  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# install dependency
RUN apt-get install -y qemu
RUN apt-get install -y libvirt0

WORKDIR /hyper-installer
