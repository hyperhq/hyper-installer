# not support hypercontainer
FROM centos:6.8
MAINTAINER Jimmy Xu <jimmy@hyper.sh>

# install common package
RUN yum install -y wget curl git vim ca-certificates \
    && yum clean all

# update qemu to 2.4.1
RUN yum install -y gcc libuuid-devel libaio-devel spice-server-devel zlib-devel \
    gnutls-devel cyrus-sasl-devel glib2-devel libaio-devel spice-protocol flex bison libtool \
    libcap-devel libattr-devel \
    && yum clean all
ENV QEMU_VER 2.4.1
RUN curl -O http://wiki.qemu-project.org/download/qemu-${QEMU_VER}.tar.bz2 \
    && tar -xjf qemu-${QEMU_VER}.tar.bz2 \
    && cd qemu-${QEMU_VER} \
    && ./configure --prefix=/usr/local/ --target-list=x86_64-softmmu --enable-vnc --disable-xen --enable-vnc-tls --enable-vnc-sasl --enable-kvm  --enable-linux-aio --disable-docs --enable-vhost-net --disable-libiscsi --disable-smartcard-nss --enable-debug --enable-uuid --enable-virtfs \
    && make && make install \
    && ln -s /usr/local/bin/qemu-system-x86_64 /usr/bin/qemu-system-x86_64 \
    && rm -rf qemu-${QEMU_VER}.tar.bz2

WORKDIR /hyper-installer
