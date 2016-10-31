Test hyper install script in docker container
=============================================

## Dependency

- qemu 2+
- libvirt

## Usage

> example

```
cd centos

//build image hyperhq/test-installer-centos:7.2.1511
./util.sh build

//run container test-installer-centos
./util.sh run

//install hypercli in container
./util.sh test_hyper

//install hypercontainer in container
./util.sh test_hypercontainer
```
