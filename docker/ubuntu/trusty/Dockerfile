# not support hypercontainer
FROM ubuntu:14.04
MAINTAINER Jimmy Xu <jimmy@hyper.sh>

ENV DEBIAN_FRONTEND noninteractive
COPY sources.list.trusty /etc/apt/sources.list

# install common package
RUN apt-get update \
    && apt-get install -y --no-install-recommends wget curl xz-utils git vim ca-certificates
#	  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# install dependency
RUN apt-get install -y qemu
RUN apt-get install -y libvirt0

# ## update dmsetup and libdevmapper
# RUN cd /root \
#     && wget http://launchpadlibrarian.net/211288612/dmsetup_1.02.99-1ubuntu1_amd64.deb \
#     && wget http://launchpadlibrarian.net/211288609/libdevmapper1.02.1_1.02.99-1ubuntu1_amd64.deb \
#     && dpkg -i libdevmapper1.02.1_1.02.99-1ubuntu1_amd64.deb \
#                dmsetup_1.02.99-1ubuntu1_amd64.deb \
#     && rm -rf libdevmapper1.02.1_1.02.99-1ubuntu1_amd64.deb \
#               dmsetup_1.02.99-1ubuntu1_amd64.deb

WORKDIR /hyper-installer
