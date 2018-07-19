#!/bin/bash
# Copyright (c) 2018 The BitCore BTX Core Developers (dalijolijo)
# Script btx-insight-docker.sh
#set -e

#
# Define Variables for BTX Insight
#
GIT_REPO="dalijolijo"
GIT_PROJECT="BTXinsight-docker"
DOCKER_REPO="dalijolijo"
IMAGE_NAME="btx-insight-docker"
IMAGE_TAG="16.04"
CONTAINER_NAME="btx-insight-docker"
DEFAULT_PORT="8555"
RPC_PORT="8556"
TOR_PORT="9051"
ZMQ_PORT="28332"
API_PORT="3001"
WEB="bitcore.cc" # without "https://" and without the last "/" (only HTTPS accepted)
BOOTSTRAP="bootstrap.tar.gz"

#
# Color definitions
#
RED='\033[0;31m'
GREEN='\033[0;32m'
NO_COL='\033[0m'
BTX_COL='\033[1;35m'

clear
printf "\n\nRUN ${BTX_COL}BITCORE (BTX)${NO_COL} INSIGHT DOCKER SOLUTION\n"

#
# Docker Installation
#
if ! type "docker" > /dev/null; then
  curl -fsSL https://get.docker.com | sh
fi

#
# Firewall Setup
#
printf "\nDownload needed Helper-Scripts"
printf "\n------------------------------\n"
wget https://raw.githubusercontent.com/${GIT_REPO}/${GIT_PROJECT}/master/check_os.sh -O check_os.sh
chmod +x ./check_os.sh
source ./check_os.sh
rm ./check_os.sh
wget https://raw.githubusercontent.com/${GIT_REPO}/${GIT_PROJECT}/master/firewall_config.sh -O firewall_config.sh
chmod +x ./firewall_config.sh
source ./firewall_config.sh ${DEFAULT_PORT} ${RPC_PORT} ${TOR_PORT} ${ZMQ_PORT} ${API_PORT}
rm ./firewall_config.sh

#
# Run the docker container from BTX Insight Docker Image
#
printf "\nStart ${BTX_COL}BitCore (BTX)${NO_COL} Insight Docker Container"
printf "\n--------------------------------------------\n"
sudo docker ps | grep ${CONTAINER_NAME} >/dev/null
if [ $? -eq 0 ]; then
    printf "${RED}Conflict! The container name \'${CONTAINER_NAME}\' is already in use.${NO_COL}\n"
    printf "\nDo you want to stop the running container to start the new one?\n"
    printf "Enter [Y]es or [N]o and Hit [ENTER]: "
    read STOP

    if [[ $STOP =~ "Y" ]] || [[ $STOP =~ "y" ]]; then
        docker stop ${CONTAINER_NAME}
    else
        printf "\nDocker Setup Result"
        printf "\n-------------------\n"
        printf "${RED}Canceled the Docker Setup without starting ${BTX_COL}BitCore (BDS)${NO_COL} Insight Docker Container.${NO_COL}\n\n"
        exit 1
    fi
fi
docker rm ${CONTAINER_NAME} 2>/dev/null

#
# Run BTX Insight Docker Container
#
docker run \
 --rm \
 -p ${DEFAULT_PORT}:${DEFAULT_PORT} \
 -p ${RPC_PORT}:${RPC_PORT} \
 -p ${TOR_PORT}:${TOR_PORT} \
 -p ${ZMQ_PORT}:${ZMQ_PORT} \
 -p ${API_PORT}:${API_PORT} \
 --detach \
 --name ${CONTAINER_NAME} \
 -e WEB="${WEB}" \
 -e BOOTSTRAP="${BOOTSTRAP}" \
 ${DOCKER_REPO}/${IMAGE_NAME}:${IMAGE_TAG}

#
# Start in Testnet?
# 
printf "\nDo you want to start the BTXinsight in TESTNET?\n"
printf "Enter [Y]es or [N]o and Hit [ENTER]: "
read TESTNET

# Restart bitcored to accept the config change (testnet=1)
if [[ $TESTNET =~ "Y" ]] || [[ $TESTNET =~ "y" ]]; then
    printf "Restart bitcored to accept the config change."

    # Change config file: Add testnet=1
    docker exec ${CONTAINER_NAME} bash -c "echo 'testnet=1' >> /home/bitcore/bitcore-livenet/bin/mynode/data/bitcore.conf" 

    # Wait until Daemon bitcored is running
    function is_running {
       running=$(docker exec "$1" supervisorctl status | grep "RUNNING")
       if [ -z "$running" ]; then
          printf "."
          true;
       else
          printf "\n"
          false;
       fi
    return $?;
    }

    printf "Please wait until Daemon bitcored is started..."
    while is_running ${CONTAINER_NAME} ; do true; done
    docker exec ${CONTAINER_NAME} supervisorctl restart bitcored
fi

#
# Show result and give user instructions
#
sleep 5
clear
printf "\n${BTX_COL}BitCore (BTX)${GREEN} Insight Docker Solution${NO_COL}\n"
sudo docker ps | grep ${CONTAINER_NAME} >/dev/null
if [ $? -ne 0 ];then
    printf "${RED}Sorry! Something went wrong. :(${NO_COL}\n"
else
    printf "${GREEN}GREAT! Your ${BTX_COL}BitCore (BTX)${GREEN} Insight Docker is running now! :)${NO_COL}\n"
    printf "\nShow your running Docker Container \'${CONTAINER_NAME}\' with ${GREEN}'docker ps'${NO_COL}\n"
    sudo docker ps | grep ${CONTAINER_NAME}
    printf "\nJump inside the ${BTX_COL}BitCore (BTX)${NO_COL} Insight Docker Container with ${GREEN}'docker exec -it ${CONTAINER_NAME} bash'${NO_COL}\n"
    printf "\nCheck Log Output of ${BTX_COL}BitCore (BTX)${NO_COL} Insight with ${GREEN}'docker logs ${CONTAINER_NAME}'${NO_COL}\n"
    printf "${GREEN}HAVE FUN!${NO_COL}\n\n"
fi

#DEBUG
docker exec btx-insight-docker cat /home/bitcore/bitcore-livenet/bin/mynode/data/bitcore.conf

