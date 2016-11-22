FROM debian:8.5
MAINTAINER Jimmy Xu <jimmy@hyper.sh>

ENV DEBIAN_FRONTEND noninteractive
COPY sources.list.jessie /etc/apt/sources.list

# install common package
RUN apt-get update \
    && apt-get install -y --no-install-recommends wget curl xz-utils git vim ca-certificates
#	  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#####################################################################
#    install libvirt0(require libvirt0_1.2.16-2ubuntu11.15.10.3+)   #
#####################################################################
## install libdbus-1-3_1.9.20
RUN apt-get install -y libapparmor1 libcap-ng0
RUN cd /root && wget http://launchpadlibrarian.net/215017531/libdbus-1-3_1.9.20-1ubuntu1_amd64.deb \
    && wget http://launchpadlibrarian.net/215017529/dbus_1.9.20-1ubuntu1_amd64.deb \
    && dpkg -i libdbus-1-3_1.9.20-1ubuntu1_amd64.deb dbus_1.9.20-1ubuntu1_amd64.deb
## install libxen-4.5_4.5.1
RUN apt-get install -y libxenstore3.0 libyajl2
RUN cd /root && wget http://launchpadlibrarian.net/216308679/libxen-4.5_4.5.1-0ubuntu1_amd64.deb \
    && dpkg -i libxen-4.5_4.5.1-0ubuntu1_amd64.deb
## install libvirt0_1.2.16-2
RUN apt-get install -y libavahi-client3 libavahi-common3 libnl-3-200 libnuma1 libxml2
RUN cd /root && wget http://launchpadlibrarian.net/234853156/libvirt0_1.2.16-2ubuntu11.15.10.3_amd64.deb \
    && dpkg -i libvirt0_1.2.16-2ubuntu11.15.10.3_amd64.deb

## update dmsetup and libdevmapper
RUN cd /root \
    && wget http://launchpadlibrarian.net/211288612/dmsetup_1.02.99-1ubuntu1_amd64.deb \
    && wget http://launchpadlibrarian.net/211288609/libdevmapper1.02.1_1.02.99-1ubuntu1_amd64.deb \
    && dpkg -i libdevmapper1.02.1_1.02.99-1ubuntu1_amd64.deb \
               dmsetup_1.02.99-1ubuntu1_amd64.deb

##########################
#      install qemu      #
##########################
RUN apt-get install -y qemu

WORKDIR /hyper-installer
