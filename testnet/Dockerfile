#Copyright (c) 2018 The Bitcore BTX Core Developers (dalijolijo)

# Use an official Ubuntu runtime as a parent image
FROM limxtec/crypto-lib-ubuntu:16.04

LABEL maintainer="The Bitcore BTX Core Developers"

ENV GIT dalijolijo
USER root
WORKDIR /home
SHELL ["/bin/bash", "-c"]

RUN echo '*** BTX Insight Explorer Docker Solution ***'

# Make ports available to the world outside this container
# Testnet Default Port = 8666
# Testnet RPC Port = 50332
# Testnet Tor Port = 9051
# ZMQ Port = 28332 (Block and Transaction Broadcasting with ZeroMQ)
# API Port = 3001 (Insight Explorer is avaiable at http://yourip:3001/insight and API at http://yourip:3001/insight/api)

# Creating bitcore user
RUN adduser --disabled-password --gecos "" bitcore && \
    usermod -a -G sudo,bitcore bitcore

# Add NodeJS (Version 8) Source
RUN apt-get update && \
    apt-get install -y curl \
                       sudo && \
    curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -

# Running updates and installing required packages
# New version libzmq5-dev needed?
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y build-essential \
                            git \
                            libzmq3-dev \
                            nodejs \
                            supervisor \
                            vim \
                            wget

# Update Package npm to latest version
RUN npm i npm@latest -g

# Installing required packages for compiling
RUN apt-get install -y  apt-utils \
                        autoconf \
                        automake \
                        autotools-dev \
                        build-essential \
                        libboost-all-dev \
                        libevent-dev \
                        libminiupnpc-dev \
                        libssl-dev \
                        libtool \
                        pkg-config \
                        software-properties-common
RUN sudo add-apt-repository ppa:bitcoin/bitcoin
RUN sudo apt-get update && \
    sudo apt-get -y upgrade
RUN apt-get install -y libdb4.8-dev \
                       libdb4.8++-dev

# Copy bitcored to bin/mynode
#RUN mkdir -p /home/bitcore/src/ && \
#    cd /home/bitcore/src/ && \
#    wget https://github.com/LIMXTEC/BitCore/releases/download/0.15.1.0/linux.Ubuntu.16.04.LTS-static-libstdc.tar.gz && \
#    tar xzf *.tar.gz && \
#    strip bitcored && \
#    rm *.tar.gz

# Cloning and Compiling BitCore Wallet
RUN mkdir -p /home/bitcore/src/ && \
    cd /home/bitcore && \
    git clone https://github.com/LIMXTEC/BitCore.git && \
    cd BitCore && \
    ./autogen.sh && \
    ./configure --disable-dependency-tracking --enable-tests=no --without-gui --disable-hardening && \
    make && \
    cd /home/bitcore/BitCore/src && \
    strip bitcored && \
    chmod 775 bitcored && \
    cp bitcored /home/bitcore/src/ && \
    cd /home/bitcore && \
    rm -rf BitCore

# Install bitcore-node-btx
RUN cd /home/bitcore && \
    git clone -b testnet https://github.com/${GIT}/bitcore-node-btx.git bitcore-testnet && \
    cd /home/bitcore/bitcore-testnet && \
    npm install

ENV BTX_NET "/home/bitcore/bitcore-testnet"

# Create Bitcore Node
# Hint: bitcore-node create -d <bitcoin-data-dir> mynode
RUN cd ${BTX_NET}/bin && \
    chmod 777 bitcore-node && \
    sync && \
    ./bitcore-node create -d ${BTX_NET}/bin/mynode/data mynode --testnet

# Install insight-api-btx
RUN cd ${BTX_NET}/bin/mynode/node_modules && \
    git clone https://github.com/${GIT}/insight-api-btx.git && \
    cd ${BTX_NET}/bin/mynode/node_modules/insight-api-btx && \
    npm install

# Install insight-ui-btx
RUN cd ${BTX_NET}/bin/mynode/node_modules && \
    git clone https://github.com/${GIT}/insight-ui-btx.git && \
    cd ${BTX_NET}/bin/mynode/node_modules/insight-ui-btx && \
    npm install

# Install bitcore-message-btx
RUN cd ${BTX_NET}/bin/mynode/node_modules && \
    git clone https://github.com/${GIT}/bitcore-message-btx.git && \
    cd ${BTX_NET}/bin/mynode/node_modules/bitcore-message-btx && \
    npm install save

# Remove duplicate node_module 'bitcore-lib' to prevent startup errors such as:
#   "More than one instance of bitcore-lib found. Please make sure to require bitcore-lib and check that submodules do
#   not also include their own bitcore-lib dependency."
RUN rm -Rf ${BTX_NET}/bin/mynode/node_modules/bitcore-node-btx/node_modules/bitcore-lib-btx && \
    rm -Rf ${BTX_NET}/bin/mynode/node_modules/insight-api-btx/node_modules/bitcore-lib-btx && \
    rm -Rf ${BTX_NET}/bin/mynode/node_modules/bitcore-lib-btx

# Install bitcore-lib-btx (not needed: part of another module)
RUN cd ${BTX_NET}/bin/mynode/node_modules && \
    git clone https://github.com/${GIT}/bitcore-lib-btx.git && \
    cd ${BTX_NET}/bin/mynode/node_modules/bitcore-lib-btx && \
    npm install

# Install bitcore-build-btx.git
RUN cd ${BTX_NET}/bin/mynode/node_modules && \
    git clone https://github.com/${GIT}/bitcore-build-btx.git && \
    cd ${BTX_NET}/bin/mynode/node_modules/bitcore-build-btx && \
    npm install

# Install bitcore-wallet-service
# See: https://github.com/dalijolijo/bitcore-wallet-service-joli/blob/master/installation.md
# Reference: https://github.com/m00re/bitcore-docker
# This will launch the BWS service (with default settings) at http://localhost:3232/bws/api.
# BWS needs mongoDB. You can configure the connection at config.js
#RUN cd ${BTX_NET}/bin/mynode/node_modules && \
#    git clone https://github.com/${GIT}/bitcore-wallet-service-btx.git && \
#    cd ${BTX_NET}/bin/mynode/node_modules/bitcore-wallet-service-btx && \
#    npm install
# Configuration needed before start
#RUN npm start
#RUN rm -Rf ${BTX_NET}/bin/mynode/node_modules/bitcore-wallet-service/node_modules/bitcore-lib-btx

# Cleanup
RUN apt-get -y remove --purge build-essential && \
    apt-get -y autoremove && \
    apt-get -y clean

# Copy bitcored to the correct bitcore-testnet/bin/ directory
RUN cp /home/bitcore/src/bitcored ${BTX_NET}/bin/

# Copy JSON bitcore-node.json
COPY bitcore-node.json ${BTX_NET}/bin/mynode/

# Copy Supervisor Configuration
COPY *.sv.conf /etc/supervisor/conf.d/

# Copy start script
COPY start_testnet.sh /usr/local/bin/start_testnet.sh
RUN rm -f /var/log/access.log && mkfifo -m 0666 /var/log/access.log && \
    chmod 755 /usr/local/bin/*

ENV TERM linux
CMD ["/usr/local/bin/start_testnet.sh"]
