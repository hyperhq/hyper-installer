FROM ubuntu:16.04
MAINTAINER Jimmy Xu <jimmy@hyper.sh>

ENV DEBIAN_FRONTEND noninteractive
COPY sources.list.xenial /etc/apt/sources.list

# qemu 2.5.0
RUN apt-get update \
    && apt-get install -y --no-install-recommends qemu-kvm qemu wget vim \
    libavahi-client3 libavahi-common3 libnl-3-200 libxml2 libicu55 xml-core sgml-base libavahi-common-data libvirt0 \
	  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
