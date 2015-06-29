There scripts are used to install hyper cli and hyperd


## Description

 - **Hyper version**
   - hyper for kvm/qemu
   - hyper for xen

 - **Install method**
  - curl/get
  - download tgz


## Usage


### 1 install hyper for kvm/qemu

#### 1.1 curl / wget

	curl -sSL https://hyper.sh/install | bash
    or
    wget -qO- https://hyper.sh/install | bash


#### 1.2 download tgz

    curl -O http://hyper-install.s3.amazonaws.com/hyper-latest.tgz
    or
    wget -c http://hyper-install.s3.amazonaws.com/hyper-latest.tgz

    tar xzvf hyper-latest.tgz
    cd hyper-pkg
    ./bootstrap.sh


### 2 install hyper for xen

#### 2.1 curl / wget

	curl -sSL https://hyper.sh/install-xen | bash
	or
    wget -qO- https://hyper.sh/install-xen | bash


#### 2.2 download tgz

    curl -O http://hyper-install.s3.amazonaws.com/hyper-xen-latest.tgz
    or
    wget -c http://hyper-install.s3.amazonaws.com/hyper-xen-latest.tgz

    tar xzvf hyper-xen-latest.tgz
    cd hyper-pkg-xen
    ./bootstrap.sh
