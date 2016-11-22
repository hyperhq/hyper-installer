#!/bin/bash

set -e

repo="hyperhq/test-installer-ubuntu"
tag="14.04"
image=${repo}:${tag}
container="test-installer-ubuntu-trusty"

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
      --privileged \
      --hostname ${container} \
      --name ${container} \
      --env HTTP_PROXY=$HTTP_PROXY  --env HTTPS_PROXY=$HTTPS_PROXY \
      -v `pwd`/../../../../hyper-installer:/hyper-installer \
      $image top
    echo "---------------------------------------------------"
    docker ps -a --filter="name=${container}"
    cat <<EOF

---------------------------------------------------
Run the following command to enter container:
    docker exec -it ${container} bash
EOF
}

function test_hyper() {
  echo -e "\ncheck conainer from [${image}] ..."
  cnt=`docker ps -a --filter="name=${container}" | wc -l`
  if [ $cnt -eq 1 ];then
    run
  fi
  docker exec -it ${container} bash -c "curl -sSL https://hyper.sh/install | bash"
}

function test_hypercontainer() {
  echo -e "\ncheck conainer from [${image}] ..."
  cnt=`docker ps -a --filter="name=${container}" | wc -l`
  if [ $cnt -eq 1 ];then
    run
  fi
  docker exec -it ${container} bash -c "curl -sSL https://hypercontainer.io/install | bash"
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
    "test_hyper")
        test_hyper
        ;;
    "test_hypercontainer")
        test_hypercontainer
        ;;
    *)
        cat <<EOF
usage:
    ./util.sh build                # build only
    ./util.sh push                 # build and push
    ./util.sh run                  # run only
    ./util.sh test_hyper           # test install script for hypercli of Hyper.sh
    ./util.sh test_hypercontainer  # test install script for hypercontainer
EOF
    exit 1
        ;;
esac



echo -e "\n=============================================================="
echo "Done!"
