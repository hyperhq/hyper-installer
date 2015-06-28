#!/bin/bash
# Description:  This script is used to install hyper cli and hyperd
# Usage:
#  install from remote
#    wget -qO- https://hyper.sh/install | bash
#    curl -sSL https://hyper.sh/install | bash
# install from local
#    ./bootstrap.sh
BASE_DIR=$(cd "$(dirname "$0")"; pwd); cd ${BASE_DIR}
DEV_MODE=""; SLEEP_SEC=10; SUPPORT_XEN="";
if [ $# -eq 1 -a "$1" == "--dev" ];then
  DEV_MODE="-dev"; SLEEP_SEC=3; echo "[test mode]"
fi
set -e
########## Variable ##########
CURRENT_USER="$(id -un 2>/dev/null || true)"
BOOTSTRAP_DIR="/tmp/hyper-bootstrap-${CURRENT_USER}"
########## Parameter ##########
S3_URL="http://hyper-install${DEV_MODE}.s3.amazonaws.com"
PKG_FILE="hyper-latest${DEV_MODE}.tgz"
UNTAR_DIR="hyper-pkg"
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
BLUE=`tput setaf 4`
WHITE=`tput setaf 7`
LIGHT=`tput bold `
RESET=`tput sgr0`
#Error Message
ERR_ROOT_PRIVILEGE_REQUIRED=(10 "This install script need root privilege, please retry use 'sudo' or root user!")
ERR_NOT_SUPPORT_PLATFORM=(20 "Sorry, Hyper only support x86_64 platform!")
ERR_NOT_SUPPORT_DISTRO=(21 "Sorry, Hyper only support (${SUPPORT_DISTRO[@]}) now!")
ERR_NOT_SUPPORT_DISTRO_VERSION=(22)
ERR_DOCKER_NOT_INSTALL=(23 "Please install docker 1.5+ first!")
ERR_DOCKER_LOW_VERSION=(24 "Need Docker version 1.5 at least!")
ERR_DOCKER_NOT_RUNNING=(25 "Docker daemon isn't running!")
ERR_DOCKER_GET_VER_FAILED=(26 "Can not get docker version!")
ERR_QEMU_NOT_INSTALL=(27 "Please install Qemu 2.0+ first!")
ERR_QEMU_LOW_VERSION=(28 "Need Qemu version 2.0 at least!")
ERR_XEN_NOT_INSTALL=(29 "Please install xen 4.5+ first!")
ERR_XEN_GET_VER_FAILED=(30 "Can not get xen version, xen daemon isn't running!")
ERR_XEN_VER_LOW=(31 "Sorry, hyper only support xen 4.5+")
ERR_FETCH_INST_PKG_FAILED=(32 "Fetch install package failed, please retry!")
ERR_INST_PKG_MD5_ERROR=(33 "Checksum of install package error, please retry!")
ERR_UNTAR_PKG_FAILED=(34 "Untar install package failed!")
ERR_EXEC_INSTALL_FAILED=(41 "Install hyper failed!")
ERR_INSTALL_SERVICE_FAILED=(42 "Install hyperd as service failed!")
ERR_HYPER_NOT_FOUND=(60 "Can not find hyper and hyperd after setup!")
ERR_UNKNOWN_MSG_TYPE=98
ERR_UNKNOWN=99
########## Function Definition ##########
main() {
  check_user
  check_deps
  check_hyper_before_install
  if [[ -f install.sh ]] && [[ -d bin ]] && [[ -d boot ]] && [[ -d service ]];then
    show_message debug "Install from local ${BASE_DIR}/"
    BOOTSTRAP_DIR="${BASE_DIR}"
  else
    show_message debug "Install from remote"
    fetch_hyper_package
  fi
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
    echo -e -n "+ sleep ${SLEEP_SEC} seconds${RESET}"
    n=${SLEEP_SEC}
    until [ ${n} -le 0 ]; do
      echo -n "." && n=$((n-1)) && sleep 1
    done
    echo
  fi
}
check_user() {
  BASH_C="bash -c"
  if [ "${CURRENT_USER}" != "root" ];then
    if (command_exist sudo);then
      BASH_C="sudo -E bash -c"
    else
      show_message error "${ERR_ROOT_PRIVILEGE_REQUIRED[1]}" && exit ${ERR_ROOT_PRIVILEGE_REQUIRED[0]}
    fi
    show_message info "${WHITE}Hint: Hyper installer need root privilege\n"
    ${BASH_C} "echo -n"
  fi
}
check_deps() {
  show_message info "Check dependency "
  check_deps_platform
  check_deps_distro
  check_deps_docker
  if [ "${SUPPORT_XEN}" == "" ];then
    check_deps_qemu
  else
    check_deps_xen
  fi
  check_deps_initsystem
  show_message done " Done"
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
check_deps_docker() { #docker 1.5+ should be installed and running
  if (command_exist docker);then
    set +e
    ${BASH_C} "docker version > /dev/null 2>&1"
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
check_deps_xen() {
  set +e
  ${BASH_C} "which xl" >/dev/null 2>&1
  if [ $? -ne 0 ];then
    show_message error "${ERR_XEN_NOT_INSTALL[1]}"
    exit ${ERR_XEN_NOT_INSTALL[0]}
  else
    ${BASH_C} "xl info" >/dev/null 2>&1
    if [ $? -eq 0 ];then
      XEN_MAJOR=$( ${BASH_C} "xl info" | grep xen_major | awk '{print $3}' )
      XEN_MINOR=$( ${BASH_C} "xl info" | grep xen_minor | awk '{print $3}' )
      XEN_VERSION=$( ${BASH_C} "xl info" | grep xen_version | awk '{print $3}' )
      show_message debug "xen(${XEN_VERSION}) found"
      if [[ $XEN_MAJOR -ge 4 ]] && [[ $XEN_MINOR -ge 5 ]];then
        PKG_FILE="hyper${SUPPORT_XEN}-latest${DEV_MODE}.tgz"
        UNTAR_DIR="hyper-pkg${SUPPORT_XEN}"
      else
        show_message error "${ERR_XEN_VER_LOW[1]}"
        exit ${ERR_XEN_VER_LOW[0]}
      fi
    else
        show_message error "${ERR_XEN_GET_VER_FAILED[1]}"
        exit ${ERR_XEN_GET_VER_FAILED[0]}
    fi
  fi
  set -e
}
check_deps_qemu() { #QEMU 2.0+ should be installed
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
  show_message info "Fetch checksum and package...\n"
  set +e
  ${BASH_C} "ping -c 3 -W 2 hyper-install${DEV_MODE}.s3.amazonaws.com >/dev/null 2>&1"
  if [ $? -ne 0 ];then
    S3_URL="http://mirror-hyper-install${DEV_MODE}.s3.amazonaws.com"
  else
    S3_URL="http://hyper-install${DEV_MODE}.s3.amazonaws.com"
  fi
  local SRC_URL="${S3_URL}/${PKG_FILE}"
  local TGT_FILE="${BOOTSTRAP_DIR}/${PKG_FILE}"
  local USE_WGET=$( echo $(get_curl) | awk -F"|" '{print $1}' )
  local CURL_C=$( echo $(get_curl) | awk -F"|" '{print $2}' )
  show_message debug "${SRC_URL} => ${TGT_FILE}"
  mkdir -p ${BOOTSTRAP_DIR} && cd ${BOOTSTRAP_DIR}
  if [ -s ${TGT_FILE} ];then
    if [ "${USE_WGET}" == "true" -a "${DEV_MODE}" == "" ];then
      ${CURL_C} ${SRC_URL}.md5 2>&1 | grep --line-buffered "%" | sed -u -e "s,\.,,g" | awk '{printf("\b\b\b\b%4s", $2)}'
    else
      ${CURL_C} ${TGT_FILE}.md5 ${SRC_URL}.md5
    fi
    if [ -s "${TGT_FILE}.md5" ];then
        NEW_MD5=$( cat ${TGT_FILE}.md5 | awk '{print $1}' )
        OLD_MD5=$( md5sum ${TGT_FILE} | awk '{print $1}' )
        if [[ ! -z ${OLD_MD5} ]] && [[ ! -z ${NEW_MD5} ]] && [[ "${OLD_MD5}" != "${NEW_MD5}" ]];then
          show_message info "${LIGHT}Found new hyper version, will download it now!\n"
          ${BASH_C} "\rm  -rf ${BOOTSTRAP_DIR}/*"
        elif [ ! -z ${OLD_MD5} -a "${OLD_MD5}" == "${NEW_MD5}" ];then #no update
          ${BASH_C} "\rm  -rf ${BOOTSTRAP_DIR}/${UNTAR_DIR}"
        else
          ${BASH_C} "\rm -rf ${BOOTSTRAP_DIR}/*"
        fi
    fi
  elif [ -f ${TGT_FILE} ];then
    ${BASH_C} "\rm -rf ${BOOTSTRAP_DIR}/*"
  fi
  if [ ! -f ${TGT_FILE} ];then
    \rm -rf ${TGT_FILE}.md5 >/dev/null 2>&1
    if [ "${USE_WGET}" == "true" -a "${DEV_MODE}" == "" ];then
      ${CURL_C} ${SRC_URL}.md5 2>&1 | grep --line-buffered "%" | sed -u -e "s,\.,,g" | awk '{printf("\b\b\b\b%4s", $2)}'
      ${CURL_C} ${SRC_URL} 2>&1 | grep --line-buffered "%" | sed -u -e "s,\.,,g" | awk '{printf("\b\b\b\b%4s", $2)}'
    else
      ${CURL_C} ${TGT_FILE}.md5 ${SRC_URL}.md5
      ${CURL_C} ${TGT_FILE} ${SRC_URL}
    fi
    if [ $? -ne 0 ];then
      show_message error "${ERR_FETCH_INST_PKG_FAILED[1]}" && exit "${ERR_FETCH_INST_PKG_FAILED[0]}"
    else
      MD5_REMOTE=$(cat ${TGT_FILE}.md5 | awk '{print $1}'); MD5_LOCAL=$(md5sum ${TGT_FILE} | awk '{print $1}')
      if [ ${MD5_REMOTE} != ${MD5_LOCAL} ];then
        echo "required checksum: ${MD5_REMOTE}, but downloaded package is ${MD5_LOCAL}"
        show_message error "${ERR_INST_PKG_MD5_ERROR[1]}" && exit "${ERR_INST_PKG_MD5_ERROR[0]}"
      fi
    fi
  fi
  ${BASH_C} "cd ${BOOTSTRAP_DIR} && tar xzf ${PKG_FILE}"
  if [ $? -ne 0 ];then
    show_message error "${ERR_UNTAR_PKG_FAILED[1]}" && exit "${ERR_UNTAR_PKG_FAILED[0]}"
  fi
  BOOTSTRAP_DIR="${BOOTSTRAP_DIR}/${UNTAR_DIR}"
  show_message done " Done"
  set -e
}
install_hyper() {
  show_message info "Installing "
  set +e
  cd ${BOOTSTRAP_DIR}
  ${BASH_C} "./install.sh" 1>/dev/null
  if [ $? -ne 0 ];then
    show_message error "${ERR_EXEC_INSTALL_FAILED[1]}" && exit "${ERR_EXEC_INSTALL_FAILED[0]}"
  fi
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
  set -e
  show_message done " Done"
}
install_hyperd_service() {
  local SRC_INIT_FILE=""
  local TGT_INIT_FILE=""
  if [ "${INIT_SYSTEM}" == "sysvinit" ];then
    if [ "${LSB_DISTRO}" == "debian" -a "${LSB_CODE}" == "wheezy" ];
    then
      SRC_INIT_FILE="${BOOTSTRAP_DIR}/service/init.d/hyperd.ubuntu"
    else
      SRC_INIT_FILE="${BOOTSTRAP_DIR}/service/init.d/hyperd.${LSB_DISTRO}"
    fi
    TGT_INIT_FILE="/etc/init.d/hyperd"
  elif [ "${INIT_SYSTEM}" == "systemd" ];then
    SRC_INIT_FILE="${BOOTSTRAP_DIR}/service/systemd/hyperd.service"
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
    echo -e "\nStopping running hyperd service before install"
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
    if [ "${SUPPORT_XEN}" == "-xen" ];then
      show_message success "\nhyperd for xen is running."
    else
      show_message success "\nhyperd for kvm/qemu is running."
    fi
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
  CURL_C=""; USE_WGET="false"
  if (command_exist curl);then
    if [ "${DEV_MODE}" != "" ];then CURL_C='curl -SL -o '; else CURL_C='curl -O --progress-bar -o '; fi
  elif (command_exist wget);then
    USE_WGET="true"
    if [ "${DEV_MODE}" != "" ];then CURL_C='wget -O '; else CURL_C='wget --progress=dot '; fi
  fi
  echo "${USE_WGET}|${CURL_C}"
}
show_message() {
  case "$1" in
    debug)  if [ "${DEV_MODE}" == "-dev" ];then echo -e "\n[${BLUE}DEBUG${RESET}] : $2"; fi;;
    info)   echo -e -n "\n${WHITE}$2${RESET}" ;;
    warn)   echo -e    "\n[${YELLOW}WARN${RESET}] : $2" ;;
    done|success) echo -e "${LIGHT}${GREEN}$2${RESET}" ;;
    error|failed) echo -e "\n[${RED}ERROR${RESET}] : $2" ;;
  esac
}
#################
main
