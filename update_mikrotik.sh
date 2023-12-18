#!/bin/bash

DEBUG=0

MTIK_FW_VER=7.13
MTIK_FW_ARCH=arm

MTIK_FW_URL=https://download.mikrotik.com/routeros/$MTIK_FW_VER/
MTIK_FW=routeros-$MTIK_FW_VER-$MTIK_FW_ARCH.npk
MTIK_FW_SUM=0744a964aa3dfa130f1efe6fc3bc9c586f679269864ca3c54d55a0a8b33da5d5 #7.13 arm

MTIK_FW_WL=wireless-$MTIK_FW_VER-$MTIK_FW_ARCH.npk
MTIK_FW_WL_SUM=d9b637ca848d4e832bfca8dd13f21d7997402a119055b4cccecd1482003a8dbe #7.13 arm

trap "echo; exit" INT

log()
{
    if [ "${DEBUG}" == "1" ] ;
    then
        echo "${BASH_LINENO[1]} (${BASH_LINENO[0]}): $@"
    else
        echo "$@"
    fi
}

checkbin()
{
    log "Check for '${1}'..."
    if ! command -v ${1} &> /dev/null
    then
        log "Binary '${1}' could not be found"
        exit
    fi
}

iscpp()
{
    if [ -z "${PASS}" ] ;
    then
        scp ${SCP_OPTS} ${@}
    else
        sshpass -p ${PASS} scp ${SCP_OPTS} ${@}
    fi
}

isshp()
{
    if [ -z "${PASS}" ] ;
    then
        ssh ${SSH_OPTS} ${@}
    else
        sshpass -p ${PASS} ssh ${SSH_OPTS} ${@}
    fi
}

wping()
{
    while ! ping -c 1 -W 1 ${1} > /dev/zero 2>&1 && echo -n .; do sleep 1; done
    echo ""
}

twait()
{
    for i in $(eval echo "{1..${1}}"); do
    	echo -n "." && sleep 1;
    done
    echo ""
}

waitboot()
{
    twait ${1}
    log "Waiting for ping reply from ${IP}"
    wping ${IP}
}

rebootwait()
{
    log "Reboot device"
    isshp ${HOST} "system reboot"
    log "Waiting for reboot"
    twait ${1}
    waitboot
}

checkbin "curl"
checkbin "sshpass"
checkbin "scp"
checkbin "sha256sum"
checkbin "ping"

cd /tmp
if ! [ -f ${MTIK_FW} ]; then
    curl -O ${MTIK_FW_URL}${MTIK_FW}
fi
echo "${MTIK_FW_SUM}  ${MTIK_FW}" | sha256sum -c - || exit 0
if ! [ -f ${MTIK_FW_WL} ]; then
    curl -O ${MTIK_FW_URL}${MTIK_FW_WL}
fi
echo "${MTIK_FW_WL_SUM}  ${MTIK_FW_WL}" | sha256sum -c - || exit 0

echo ""
read -p "Enter IP [192.168.88.1]: " IP && [ -z ${IP} ] && IP=192.168.88.1
read -p "Enter Port [22]: " PORT && [ -z ${PORT} ] && PORT=22
read -p "Enter User [admin]: " USER && [ -z ${USER} ] && USER=admin
read -p "Enter Password: " -s PASS
echo ""
HOST=${USER}@${IP}
SCP_OPTS="-o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o LogLevel=error \
        -o MACs=hmac-sha1,hmac-sha2-256 \
        -o Port=${PORT}"
SSH_OPTS="-o StrictHostKeyChecking=no \
       -o UserKnownHostsFile=/dev/null \
       -o LogLevel=error \
       -o MACs=hmac-sha1,hmac-sha2-256 \
       -o ServerAliveInterval=3 \
       -o ServerAliveCountMax=3 \
       -o ConnectTimeout=20 \
       -o Port=${PORT}"


log "Copying Firmware"
iscpp ${MTIK_FW} ${HOST}:
iscpp ${MTIK_FW_WL} ${HOST}:
isshp ${HOST} system routerboard settings set auto-upgrade=yes
rebootwait 2
log "Updating Bootloader"
rebootwait 2
isshp ${HOST} system routerboard print
log "Finished"
