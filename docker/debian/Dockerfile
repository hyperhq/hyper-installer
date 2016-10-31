FROM debian:8.5
MAINTAINER Jimmy Xu <jimmy@hyper.sh>

ENV DEBIAN_FRONTEND noninteractive
COPY sources.list.jessie /etc/apt/sources.list

#qemu 2.1.2
RUN apt-get update \
    && apt-get install -y --no-install-recommends qemu-kvm qemu libvirt0 \
    wget curl git vim ca-certificates \
	  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN cd /root/ && wget http://launchpadlibrarian.net/211288612/dmsetup_1.02.99-1ubuntu1_amd64.deb \
   && wget http://launchpadlibrarian.net/211288609/libdevmapper1.02.1_1.02.99-1ubuntu1_amd64.deb \
   && dpkg -i libdevmapper1.02.1_1.02.99-1ubuntu1_amd64.deb dmsetup_1.02.99-1ubuntu1_amd64.deb \
   && rm -rf libdevmapper1.02.1_1.02.99-1ubuntu1_amd64.deb dmsetup_1.02.99-1ubuntu1_amd64.deb
