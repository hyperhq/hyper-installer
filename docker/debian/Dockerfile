FROM debian:8.5
MAINTAINER Jimmy Xu <jimmy@hyper.sh>

ENV DEBIAN_FRONTEND noninteractive
COPY sources.list.jessie /etc/apt/sources.list

#qemu 2.1.2
RUN apt-get update \
    && apt-get install -y --no-install-recommends qemu-kvm qemu libvirt0 wget vim \
	  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
