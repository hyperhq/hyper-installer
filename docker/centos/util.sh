#!/bin/bash

set -e

repo="hyperhq/test-installer-centos"
tag="7.2.1511"
image=${repo}:${tag}
container="test-installer-centos"

# DOCKER0=$(ifconfig | grep docker0 -A1 | grep "inet " | awk '{print $2}')
# PROXY="http://${DOCKER0}:8118"

function build(){
    echo "starting build..."
    echo "=============================================================="
    CMD="docker build --build-arg http_proxy=${PROXY} --build-arg https_proxy=${PROXY} -t ${image} ."
    echo "CMD: [ ${CMD} ]"
    eval $CMD
}

function push(){
    echo -e "\nstarting push [${image}] ..."
    echo "=============================================================="
    docker push ${image}
}

function run() {
    echo -e "\ncheck old conainer from [${image}] ..."
    cnt=`docker ps -a --filter="name=${container}" | wc -l`
    if [ $cnt -ne 1 ];then
      docker rm -fv ${container}
    fi
    echo -e "\nrun conainer from [${image}] ..."
    docker run -d -t \
      --name ${container} \
      -v `pwd`/../../../hyper-installer:/hyper-installer \
      $image top
    echo "---------------------------------------------------"
    docker ps -a --filter="name=${container}"
    cat <<EOF

---------------------------------------------------
Run the following command to enter container:
    docker exec -it ${container} bash
EOF
}

case "$1" in
    "build")
        build
        ;;
    "push")
        build
        push
        ;;
    "run")
        run
        ;;
    *)
        cat <<EOF
usage:
    ./util.sh build       # build only
    ./util.sh push        # build and push
    ./util.sh run         # run only
EOF
    exit 1
        ;;
esac



echo -e "\n=============================================================="
echo "Done!"
