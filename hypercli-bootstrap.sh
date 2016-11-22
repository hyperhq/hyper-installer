#!/bin/bash
# Description:  This script is used to install hyper cli and hyperd
# Usage:
#  install from remote
#    wget -qO- https://hyper.sh/install | bash
#    curl -sSL https://hyper.sh/install | bash
# install from local
#    ./hypercli-bootstrap.sh
WORK_DIR=$(pwd)
BASE_DIR=$(cd "$(dirname "$0")"; pwd); cd ${BASE_DIR}
SLEEP_SEC=10
set -e
########## Variable ##########
CURRENT_USER=$(id -un 2>/dev/null || true)
BOOTSTRAP_DIR="/tmp/hypercli-pkg-${CURRENT_USER}"
BASH_C="bash -c"
########## Parameter ##########
S3_URL="https://hyper-install.s3.amazonaws.com"
PKG_FILE_LINUX="hyper-linux-x86_64.tar.gz"
PKG_FILE_MACOSX="hyper-mac.bin.zip"
SUPPORT_EMAIL="support@hyper.sh"
#Color Constant
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
WHITE=`tput setaf 7`
LIGHT=`tput bold `
RESET=`tput sgr0`
#Error Message
ERR_NOT_SUPPORT_OS=(10 "Sorry, hypercli support Linux and MacOSX only!")
ERR_FETCH_PKG_FAILED=(20 "Fetch hypercli package failed, please retry!")
ERR_PKG_MD5_ERROR=(30 "Checksum of install package error, please retry!")
ERR_UNKNOWN=99
########## Helper Function Definition ##########
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
    CURL_C='curl -# -SL -o '
  elif (command_exist wget);then
    USE_WGET="true"
    CURL_C='wget -O '
  fi
  echo "${USE_WGET}|${CURL_C}"
}
show_message() {
  case "$1" in
    debug)  echo -e "\n[${BLUE}DEBUG${RESET}] : $2";;
    info)   echo -e -n "\n${WHITE}$2${RESET}" ;;
    warn)   echo -e    "\n[${YELLOW}WARN${RESET}] : $2" ;;
    done|success) echo -e "${LIGHT}${GREEN}$2${RESET}" ;;
    error|failed) echo -e "\n[${RED}ERROR${RESET}] : $2" ;;
  esac
}
########## Main Function Definition ##########
main() {
  show_message info "Welcome to Install hyper client for HYPER_...\n"
  check_os_type
  fetch_hypercli
  extract_hypercli
  exit 0
}
check_os_type() {
  OS_TYPE=$(uname -a | awk '{print $1}')
  case "${OS_TYPE}" in
    Linux)  PKG_FILE="${PKG_FILE_LINUX}";;
    Darwin) PKG_FILE="${PKG_FILE_MACOSX}";;
    *) show_message error "${ERR_NOT_SUPPORT_OS[1]}" && exit "${ERR_NOT_SUPPORT_OS[0]}"
      ;;
  esac
}
fetch_hypercli() {
  set +e
  ${BASH_C} "ping -c 3 -W 2 hyper-install.s3.amazonaws.com >/dev/null 2>&1"
  if [ $? -ne 0 ];then
    S3_URL="https://mirror-hyper-install.s3.amazonaws.com"
  fi
  local SRC_URL="${S3_URL}/${PKG_FILE}"
  local TGT_FILE="${BOOTSTRAP_DIR}/${PKG_FILE}"
  local USE_WGET=$(echo $(get_curl) | awk -F"|" '{print $1}')
  local CURL_C=$(echo $(get_curl) | awk -F"|" '{print $2}')
  show_message info "${SRC_URL} => ${TGT_FILE}\n"
  mkdir -p ${BOOTSTRAP_DIR} && cd ${BOOTSTRAP_DIR}
  if [ -s ${TGT_FILE} ];then
    show_message info "${TGT_FILE} is exist, Check new version...\n"
    if [ "${USE_WGET}" == "true" ];then
      ${CURL_C} ${SRC_URL}.md5 2>&1 | grep --line-buffered "%" | sed -u -e "s,\.,,g" | awk '{printf("\b\b\b\b%4s", $2)}'
    else
      ${CURL_C} ${TGT_FILE}.md5 ${SRC_URL}.md5
    fi
    if [ -s "${TGT_FILE}.md5" ];then
      case "${OS_TYPE}" in
        Linux)
          NEW_MD5=$(cat ${TGT_FILE}.md5 | awk '{print $1}')
          OLD_MD5=$(md5sum ${TGT_FILE} | awk '{print $1}')
          ;;
        Darwin)
          NEW_MD5=$(cat ${TGT_FILE}.md5 | awk '{print $NF}')
          OLD_MD5=$(md5 ${TGT_FILE} | awk '{print $NF}')
          ;;
        esac
        if [[ ! -z ${OLD_MD5} ]] && [[ ! -z ${NEW_MD5} ]] && [[ "${OLD_MD5}" != "${NEW_MD5}" ]];then
          show_message info "${LIGHT}hypercli updated, starting download...\n"
          ${BASH_C} "\rm  -rf ${BOOTSTRAP_DIR}/*"
        elif [[ ! -z ${OLD_MD5} ]] && [[ "${OLD_MD5}" == "${NEW_MD5}" ]];then #no update
          echo -n
        else
          ${BASH_C} "\rm -rf ${BOOTSTRAP_DIR}/*"
        fi
    fi
  elif [ -f ${TGT_FILE} ];then
    ${BASH_C} "\rm -rf ${BOOTSTRAP_DIR}/*"
  fi
  if [ ! -f ${TGT_FILE} ];then
    \rm -rf ${TGT_FILE}.md5 >/dev/null 2>&1
    show_message info "Fetch checksum...\n"
    if [ "${USE_WGET}" == "true" ];then
      ${CURL_C} ${SRC_URL}.md5 2>&1 | grep --line-buffered "%" | sed -u -e "s,\.,,g" | awk '{printf("\b\b\b\b%4s", $2)}'
      ${CURL_C} ${SRC_URL} 2>&1 | grep --line-buffered "%" | sed -u -e "s,\.,,g" | awk '{printf("\b\b\b\b%4s", $2)}'
    else
      ${CURL_C} ${TGT_FILE}.md5 ${SRC_URL}.md5
      ${CURL_C} ${TGT_FILE} ${SRC_URL}
    fi
    if [ $? -ne 0 ];then
      show_message error "${ERR_FETCH_PKG_FAILED[1]}" && exit "${ERR_FETCH_PKG_FAILED[0]}"
    else
      case "${OS_TYPE}" in
        Linux)  MD5_REMOTE=$(cat ${TGT_FILE}.md5 | awk '{print $1}')
                MD5_LOCAL=$(md5sum ${TGT_FILE} | awk '{print $1}')
                ;;
        Darwin) MD5_REMOTE=$(cat ${TGT_FILE}.md5 | awk '{print $NF}')
                MD5_LOCAL=$(md5 ${TGT_FILE} | awk '{print $NF}')
                ;;
      esac
      if [[ ${MD5_REMOTE} != ${MD5_LOCAL} ]];then
        echo "required checksum: ${MD5_REMOTE}, but downloaded package is ${MD5_LOCAL}"
        show_message error "${ERR_PKG_MD5_ERROR[1]}" && exit "${ERR_PKG_MD5_ERROR[0]}"
      fi
    fi
  fi
  set -e
}
extract_hypercli() {
  cd ${WORK_DIR}
  case "${OS_TYPE}" in
    Linux)  PKG_FILE="${PKG_FILE_LINUX}"
      ${BASH_C} "tar xzf ${BOOTSTRAP_DIR}/${PKG_FILE} -C ${WORK_DIR}"
      md5sum hyper | awk '{printf "MD5 (hyper) = %s\n", $1}'
      ;;
    Darwin) PKG_FILE="${PKG_FILE_MACOSX}"
      ${BASH_C} "unzip -o ${BOOTSTRAP_DIR}/${PKG_FILE} -d ${WORK_DIR}"
      md5 hyper
      ;;
    *) show_message error "${ERR_NOT_SUPPORT_OS[1]}" && exit "${ERR_NOT_SUPPORT_OS[0]}"
      ;;
  esac
  chmod +x hyper
  cat <<EOF
hypercli '${WORK_DIR}/hyper' is ready

==============================================================================
[QuickStart]
#Step 1: get Hyper_ credential.
  Register a new account on https://console.hyper.sh, then create a credential.
#Step 2: Config hyper cli
  ./hyper config
#Step 3: use hyper cli
  ./hyper pull busybox
  ./hyper images
  ./hyper run -t busybox echo helloworld
  ./hyper ps -a

For more information, please go to https://docs.hyper.sh
For Community Edition of Hyper, please go to https://hypercontainer.io
EOF
}

#################
main
