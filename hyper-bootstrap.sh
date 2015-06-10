#!/bin/bash
#*******************************************************************
# Description:  This script is used to install hyper cli and hyperd
#*******************************************************************
# Usage:
#   wget -qO- https://hyper.sh/install | bash
#   curl -sSL https://hyper.sh/install | bash
#*******************************************************************
DEV_MODE=""
SLEEP_SEC=10
if [ $# -eq 1 -a "$1" == "--dev" ];then
  DEV_MODE="-dev"; SLEEP_SEC=3; echo "[test mode]"
fi
set -e
########## Variable ##########
CURRENT_USER="$(id -un 2>/dev/null || true)"
BOOTSTRAP_DIR="/tmp/hyper-bootstrap-${CURRENT_USER}"
########## Parameter ##########
S3_URL="https://hyper-install${DEV_MODE}.s3.amazonaws.com"
PKG_FILE="hyper-latest${DEV_MODE}.tgz"
UNTAR_DIR="hyper-dev"
SUPPORT_EMAIL="support@hyper.sh"
########## Constant ##########
SUPPORT_DISTRO=(debian ubuntu fedora centos)
UBUNTU_CODE=(trusty utopic vivid)
DEBIAN_CODE=(jessie wheezy)
CENTOS_VER=(6 7)
FEDORA_VER=(21 22)
#Color Constant
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
WHITE=`tput setaf 7`
LIGHT=`tput bold `
RESET=`tput sgr0`
#Error Message
ERR_ROOT_PRIVILEGE_REQUIRED=(10 "This install script needs to run as root, please use sudo!")
ERR_NOT_SUPPORT_PLATFORM=(20 "Sorry, Hyper only support x86_64 platform!")
ERR_NOT_SUPPORT_DISTRO=(21 "Sorry, Hyper only support (${SUPPORT_DISTRO[@]}) now!")
ERR_NOT_SUPPORT_DISTRO_VERSION=(22)
ERR_DOCKER_NOT_INSTALL=(23 "Please install docker 1.5+ first!")
ERR_DOCKER_LOW_VERSION=(24 "Need Docker version 1.5 at least!")
ERR_DOCKER_NOT_RUNNING=(25 "Docker daemon isn't running!")
ERR_DOCKER_GET_VER_FAILED=(26 "Can not get docker version!")
ERR_QEMU_NOT_INSTALL=(27 "Please install Qemu 2.0+ first!")
ERR_QEMU_LOW_VERSION=(28 "Need Qemu version 2.0 at least!")
ERR_FETCH_INST_PKG_FAILED=(32 "Fetch install package failed!")
ERR_EXEC_INSTALL_FAILED=(41 "Install hyper failed!")
ERR_INSTALL_SERVICE_FAILED=(42 "Install hyperd as service failed!")
ERR_HYPER_NOT_FOUND=(60 "Can not find hyper and hyperd after setup!")
ERR_UNKNOWN_MSG_TYPE=98
ERR_UNKNOWN=99
########## Function Definition ##########
main() {
  check_hyper_before_install
  check_user
  check_deps
  fetch_hyper_package
  stop_running_hyperd
  install_hyper
  start_hyperd_service
  exit 0
}
check_hyper_before_install() {
  if (command_exist hyper hyperd);then
    echo "${WHITE}"
    cat <<COMMENT
Prompt: "hyper" appears to already installed, hyperd serive will be restart during install.
You may press Ctrl+C to abort this process.
COMMENT
    echo "+ sleep ${SLEEP_SEC} seconds"
    echo -n "${RESET}"
    n=${SLEEP_SEC}
    until [ ${n} -le 0 ]; do
      echo -n "." && n=$((n-1)) && sleep 1
    done
  fi
}
check_user() {
  BASH_C="bash -c"
  if [ "${CURRENT_USER}" != "root" ];then
    if (command_exist sudo);then
      BASH_C="sudo -E bash -c"
    elif (command_exist su);then
      BASH_C='su -c'
    else
      show_message error "${ERR_ROOT_PRIVILEGE_REQUIRED[1]}" && exit ${ERR_ROOT_PRIVILEGE_REQUIRED[0]}
    fi
    show_message info "\n${WHITE}Hint: Hyper installer need root privilege\n"
    sudo -s echo -n
  fi
}
check_deps() {
  show_message info "Check dependency "
  check_deps_platform
  check_deps_distro
  check_deps_docker
  check_deps_qemu
  check_deps_initsystem
  show_message done " Done\n"
}
check_deps_platform() {
  ARCH="$(uname -m)"
  if [ "${ARCH}" != "x86_64" ];then
    show_message error "${ERR_NOT_SUPPORT_PLATFORM[1]}" && exit ${ERR_NOT_SUPPORT_PLATFORM[0]}
  fi
  echo -n "."
}
check_deps_distro() {
  LSB_DISTRO=""; LSB_VER=""; LSB_CODE=""
  if (command_exist lsb_release);then
    LSB_DISTRO="$(lsb_release -si)"
    LSB_VER="$(lsb_release -sr)"
    LSB_CODE="$(lsb_release -sc)"
  fi
  if [ -z "${LSB_DISTRO}" ];then
    if [ -r /etc/lsb-release ];then
      LSB_DISTRO="$(. /etc/lsb-release && echo "${DISTRIB_ID}")"
      LSB_VER="$(. /etc/lsb-release && echo "${DISTRIB_RELEASE}")"
      LSB_CODE="$(. /etc/lsb-release && echo "${DISTRIB_CODENAME}")"
    elif [ -r /etc/os-release ];then
      LSB_DISTRO="$(. /etc/os-release && echo "$ID")"
      LSB_VER="$(. /etc/os-release && echo "$VERSION_ID")"
    elif [ -r /etc/fedora-release ];then
      LSB_DISTRO="fedora"
    elif [ -r /etc/debian_version ];then
      LSB_DISTRO="Debian"
      LSB_VER="$(cat /etc/debian_version)"
    fi
  fi
  LSB_DISTRO=$(echo "${LSB_DISTRO}" | tr '[:upper:]' '[:lower:]')
  if [ "${LSB_DISTRO}" == "debian" ];then
    case ${LSB_VER} in
      8) LSB_CODE="jessie";;
      7) LSB_CODE="wheezy";;
    esac
  fi
  case "${LSB_DISTRO}" in
    ubuntu|debian)
      if [ "${LSB_DISTRO}" == "ubuntu" ]
      then SUPPORT_CODE_LIST="${UBUNTU_CODE[@]}";
      else SUPPORT_CODE_LIST="${DEBIAN_CODE[@]}";
      fi
      if (echo "${SUPPORT_CODE_LIST}" | grep -v -w "${LSB_CODE}" &>/dev/null);then
        show_message error "Hyper support ${LSB_DISTRO}( ${SUPPORT_CODE_LIST} ), but current is ${LSB_CODE}(${LSB_VER})"
        exit ${ERR_NOT_SUPPORT_DISTRO_VERSION[0]}
      fi
    ;;
    centos|fedora)
      CMAJOR=$( echo ${LSB_VER} | cut -d"." -f1 )
      if [  "${LSB_DISTRO}" == "centos" ]
      then SUPPORT_VER_LIST="${CENTOS_VER[@]}";
      else SUPPORT_VER_LIST="${FEDORA_VER[@]}";
      fi
      if (echo "${SUPPORT_VER_LIST}" | grep -v -w "${CMAJOR}" &>/dev/null);then
        show_message error "Hyper support ${LSB_DISTRO}( ${SUPPORT_VER_LIST} ), but current is ${LSB_VER}"
        exit ${ERR_NOT_SUPPORT_DISTRO_VERSION[0]}
      fi
    ;;
    *) show_message error "${ERR_NOT_SUPPORT_DISTRO[1]}, but your are using '${LSB_DISTRO} ${LSB_VER}(${LSB_CODE})'"
      exit ${ERR_NOT_SUPPORT_DISTRO[0]}
    ;;
  esac
  echo -n "."
}
check_deps_docker() {
  #docker 1.5+ should be installed and running
  if (command_exist docker);then
    set +e
    sudo docker version > /dev/null 2>&1
    if [ $? -ne 0 ];then
      show_message error "${ERR_DOCKER_NOT_RUNNING[1]}\n"
      cat <<COMMENT
Please start docker service:
    sudo service docker start
COMMENT
      exit ${ERR_DOCKER_NOT_RUNNING[0]}
    fi
    local DOCKER_VER=$(${BASH_C} "docker version" 2>/dev/null | sed -ne 's/Server version:[[:space:]]*\([0-9]\{1,\}\)*/\1/p')
    set -e
    read DMAJOR DMINOR DFIX < <( echo ${DOCKER_VER} | awk -F"." '{print $1,$2,$3}')
    if [ -z ${DMAJOR} -o -z ${DMINOR} ];then
      show_message error "${ERR_DOCKER_GET_VER_FAILED[1]}"
      display_support ${ERR_DOCKER_GET_VER_FAILED[0]}
      exit ${ERR_DOCKER_GET_VER_FAILED[0]}
    fi
    if [ ${DMAJOR} -lt 1 ] || [ ${DMAJOR} -eq 1 -a ${DMINOR} -lt 5 ];then
      show_message error "${ERR_DOCKER_LOW_VERSION[1]} but current is ${DMAJOR}.${DMINOR}, please upgrade docker first!"
      exit ${ERR_DOCKER_LOW_VERSION[0]]}
    fi
  else
    show_message error "${ERR_DOCKER_NOT_INSTALL[1]}"
    if [ "${LSB_DISTRO}" == "ubuntu" ];then
      _OS="linux"
    fi
    echo -e "\nInstructions for installing Docker on ${LSB_DISTRO}${_OS}"
    echo -e "    https://docs.docker.com/installation/${LSB_DISTRO}${_OS}/\n"
    exit ${ERR_DOCKER_NOT_INSTALL[0]}
  fi
  echo -n "."
}
check_deps_qemu() {
  #QEMU 2.0+ should be installed
  if (command_exist qemu-system-x86_64);then
    local QEMU_VER=$(qemu-system-x86_64 --version | awk '{print $4}' | cut -d"," -f1)
    read QMAJOR QMINOR QFIX < <( echo ${QEMU_VER} | awk -F'.' '{print $1,$2,$3 }')
    if [ ${QMAJOR} -lt 2 ] ;then
      show_message error "${ERR_QEMU_LOW_VERSION[1]}\n" && exit ${ERR_QEMU_LOW_VERSION[0]}
    fi
  else
    show_message error "${ERR_QEMU_NOT_INSTALL[1]}\n" && exit ${ERR_QEMU_NOT_INSTALL[0]}
  fi
  echo -n "."
}
check_deps_initsystem() {
  if [ "${LSB_DISTRO}" == "ubuntu" -a "${LSB_CODE}" == "utopic" ];then
    INIT_SYSTEM="sysvinit"
  elif (command_exist systemctl);then
    INIT_SYSTEM="systemd"
  else
    INIT_SYSTEM="sysvinit"
  fi
  echo -n "."
}
fetch_hyper_package() {
  set +e
  show_message info "Fetch package "
  local SRC_URL="${S3_URL}/${PKG_FILE}"
  local TGT_FILE="${BOOTSTRAP_DIR}/${PKG_FILE}"
  local CURL_C=$(get_curl)
  mkdir -p ${BOOTSTRAP_DIR} && cd ${BOOTSTRAP_DIR}
  if [ -s ${TGT_FILE} ];then
    ${CURL_C} ${TGT_FILE}.md5 ${SRC_URL}.md5
    if [ -s "${TGT_FILE}.md5" ];then
        NEW_MD5=$( cat ${TGT_FILE}.md5 | awk '{print $1}' )
        OLD_MD5=$( md5sum ${TGT_FILE} | awk '{print $1}' )
        if [[ ! -z ${OLD_MD5} ]] && [[ ! -z ${NEW_MD5} ]] && [[ "${OLD_MD5}" != "${NEW_MD5}" ]];then
          show_message info "${LIGHT}Found new hyper version, will download it now!\n"
          ${BASH_C} "sudo rm  -rf ${BOOTSTRAP_DIR}/*"
        elif [ ! -z ${OLD_MD5} -a "${OLD_MD5}" == "${NEW_MD5}" ];then
          #no update
          ${BASH_C} "sudo rm  -rf ${BOOTSTRAP_DIR}/${UNTAR_DIR}"
        else
          ${BASH_C} "sudo rm -rf ${BOOTSTRAP_DIR}/*"
        fi
    fi
  elif [ -f ${TGT_FILE} ];then
    ${BASH_C} "sudo rm -rf ${BOOTSTRAP_DIR}/*"
  fi
  echo -n "."
  if [ ! -f ${TGT_FILE} ];then
    ${CURL_C} ${TGT_FILE} ${SRC_URL}
    if [ $? -ne 0 ];then
      show_message error "${ERR_FETCH_INST_PKG_FAILED[1]}" && exit "${ERR_FETCH_INST_PKG_FAILED[0]}"
    fi
  fi
  echo -n "."
  show_message done " Done\n"
  set -e
}
install_hyper() {
  show_message info "Installing "
  ${BASH_C} "cd ${BOOTSTRAP_DIR} && tar xzf ${PKG_FILE}"
  cd ${BOOTSTRAP_DIR}/${UNTAR_DIR}
  ${BASH_C} "./install.sh" 1> /dev/null
  echo -n "."
  if [[ -f /usr/local/bin/hyper ]] && [[ -f /usr/local/bin/hyperd ]] && [[ ! -f /usr/bin/hyper ]] && [[ ! -f /usr/bin/hyperd ]] ;then
    ${BASH_C} "ln -s /usr/local/bin/hyper /usr/bin/hyper"
    ${BASH_C} "ln -s /usr/local/bin/hyperd /usr/bin/hyperd"
  fi
  if (command_exist hyper hyperd);then
    install_hyperd_service
    echo -n "."
  else
    show_message error "${ERR_HYPER_NOT_FOUND[1]}"
    display_support ${ERR_HYPER_NOT_FOUND[0]}
    exit ${ERR_HYPER_NOT_FOUND[0]}
  fi
  show_message done " Done\n"
}
install_hyperd_service() {
  local SRC_INIT_FILE=""
  local TGT_INIT_FILE=""
  if [ "${INIT_SYSTEM}" == "sysvinit" ];then
    if [ "${LSB_DISTRO}" == "debian" -a "${LSB_CODE}" == "wheezy" ];
    then
      SRC_INIT_FILE="${BOOTSTRAP_DIR}/${UNTAR_DIR}/service/init.d/hyperd.ubuntu"
    else
      SRC_INIT_FILE="${BOOTSTRAP_DIR}/${UNTAR_DIR}/service/init.d/hyperd.${LSB_DISTRO}"
    fi
    TGT_INIT_FILE="/etc/init.d/hyperd"
  elif [ "${INIT_SYSTEM}" == "systemd" ];then
    SRC_INIT_FILE="${BOOTSTRAP_DIR}/${UNTAR_DIR}/service/systemd/hyperd.service"
    TGT_INIT_FILE="/lib/systemd/system/hyperd.service"
  fi
  if [ -s ${SRC_INIT_FILE} ];then
    ${BASH_C} "cp ${SRC_INIT_FILE} ${TGT_INIT_FILE}"
    ${BASH_C} "chmod +x ${TGT_INIT_FILE}"
  else
    show_message error "${ERR_INSTALL_SERVICE_FAILED[1]}"
    display_support ${ERR_INSTALL_SERVICE_FAILED[1]}
    exit ${ERR_INSTALL_SERVICE_FAILED[0]}
  fi
}
stop_running_hyperd() {
  set +e
  pgrep hyperd >/dev/null 2>&1
  if [ $? -eq 0 ];then
    echo -e "Stopping running hyperd service before install"
    if [ "${INIT_SYSTEM}" == "systemd" ]
    then ${BASH_C} "systemctl stop hyperd"
    else ${BASH_C} "service hyperd stop";
    fi
    sleep 3
  fi
  set -e
}
start_hyperd_service() {
  show_message info "Start hyperd service\n"
  if [ "${INIT_SYSTEM}" == "systemd" ]
  then ${BASH_C} "systemctl start hyperd"
  else ${BASH_C} "service hyperd start";
  fi
  sleep 3
  set +e
  pgrep hyperd >/dev/null 2>&1
  if [ $? -eq 0 ];then
    show_message success "\nhyperd is running."
    cat <<COMMENT
----------------------------------------------------
To see how to use hyper cli:
  sudo hyper help
To manage hyperd service:
  sudo service hyperd {start|stop|restart|status}
To get more information:
  http://hyper.sh
COMMENT
  else
    show_message warn "\nhyperd isn't running."
    cat <<COMMENT
Please try to start hyperd by manual:
  sudo service hyperd restart
  sudo service hyperd status
COMMENT
  fi
  set -e
}
display_support() {
  echo "Sorry, we are suffering from some technical issue($1), please contact ${SUPPORT_EMAIL}"
  if [ $# -eq 0 ];then exit ${ERR_UNKNOWN}
  else exit $1
  fi
}
command_exist() {
  type "$@" > /dev/null 2>&1
}
get_curl() {
  CURL_C=""
  if (command_exist wget);then
    if [ "${DEV_MODE}" != "" ];then CURL_C='wget -O '; else CURL_C='wget -qO '; fi
  elif (command_exist curl);then
    if [ "${DEV_MODE}" != "" ];then CURL_C='curl -SL -o '; else CURL_C='curl -sSL -o '; fi
  fi
  echo ${CURL_C}
}
show_message() {
  case "$1" in
    info)   echo -e -n "\n${WHITE}$2${RESET}" ;;
    warn)   echo -e    "\n[${YELLOW}WARN${RESET}] : $2" ;;
    done|success) echo -e "${LIGHT}${GREEN}$2${RESET}" ;;
    error|failed) echo -e "\n[${RED}ERROR${RESET}] : $2" ;;
  esac
}
#################
main
