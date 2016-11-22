# not support hypercontainer
FROM debian:7.11
MAINTAINER Jimmy Xu <jimmy@hyper.sh>

ENV DEBIAN_FRONTEND noninteractive
COPY sources.list.wheezy /etc/apt/sources.list

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    wget curl git vim ca-certificates
##	  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# install qemu 2.3.0
RUN apt-get install -y make bzip2 gcc \
  libgnutls-dev libsasl2-dev uuid-dev libglib2.0-dev libaio-dev libspice-server-dev libspice-protocol-dev \
  libcap-dev and libattr1-dev
ENV QEMU_VER 2.3.0
RUN curl -O http://wiki.qemu-project.org/download/qemu-${QEMU_VER}.tar.bz2 \
    && tar -xjf qemu-${QEMU_VER}.tar.bz2 \
    && cd qemu-${QEMU_VER} \
    && ./configure --prefix=/usr/local/ --target-list=x86_64-softmmu --enable-vnc --disable-xen --enable-vnc-tls --enable-vnc-sasl --enable-kvm  --enable-linux-aio --disable-docs --enable-vhost-net --disable-libiscsi --disable-smartcard-nss --enable-debug --enable-uuid --enable-virtfs \
    && make && make install \
    && ln -s /usr/local/bin/qemu-system-x86_64 /usr/bin/qemu-system-x86_64 \
    && rm -rf qemu-${QEMU_VER}.tar.bz2

# install libvirt0
RUN apt-get install -y libvirt0

WORKDIR /hyper-installer
