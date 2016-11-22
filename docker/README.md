Test hyper install script in docker container
=============================================

# Install script test report

| OS | hyper.sh | hypercontainer |
| --- | --- | --- |
| [CentOS7](centos/6) | ok | ok |
| [CentOS6](centos/7) | ok | - |
| [Fefora24](fedora/24) | ok | ok |
| [Fefora23](fedora/23) | ok | ok |
| [Ubuntu16.04(xenial)](ubuntu/xenial) | ok | ok |
| [Ubuntu14.04(trusty)](ubuntu/trusty) | ok | - |
| [Debian8(jessie)](debian/jessie) | ok | ok |
| [Debian7(wheezy)](debian/wheezy) | ok | - |

# Dependency for  hypercontainer

- qemu 2+
- libvirt

# Test install script in docker container

> For example: test under CentOS 7

```shell
$ cd centos/7

//build image hyperhq/test-installer-centos:7.2.1511
$ ./util.sh build

//run container test-installer-centos
$ ./util.sh run

//test local install script
$ docker exec -it test-installer-centos-7 bash

//install hypercli in container
$ ./util.sh test_hyper

//install hypercontainer in container
$ ./util.sh test_hypercontainer
```
