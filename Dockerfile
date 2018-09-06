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
# Default Port = 8555
# RPC Port = 8556
# Tor Port = 9051
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
    apt-get dist-upgrade -y && \
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

# Install btxcore
RUN cd /home/bitcore && \
    git clone https://github.com/${GIT}/btxcore.git bitcore-livenet && \
    cd /home/bitcore/bitcore-livenet && \
    npm install

ENV BTX_NET "/home/bitcore/bitcore-livenet"

# Create Bitcore Node
# Hint: bitcore-node create -d <bitcoin-data-dir> mynode
RUN cd ${BTX_NET}/bin && \
    chmod 777 bitcore-node && \
    sync && \
    ./bitcore-node create -d ${BTX_NET}/bin/mynode/data mynode

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

# Install bitcore-specialops-btx.git
# README: cd ~/mynode AND npm install --save bitcore-specialops-btx
RUN cd ${BTX_NET}/bin/mynode/node_modules && \
    git clone -b btx-support https://github.com/dalijolijo/bitcore-specialops-btx.git && \
    cd ${BTX_NET}/bin/mynode/node_modules/bitcore-specialops-btx && \
    npm install save

# Cleanup
RUN apt-get -y remove --purge build-essential && \
    apt-get -y autoremove && \
    apt-get -y clean

# Copy bitcored to the correct bitcore-livenet/bin/ directory
RUN cp /home/bitcore/src/bitcored ${BTX_NET}/bin/

# Copy JSON bitcore-node.json
COPY bitcore-node.json ${BTX_NET}/bin/mynode/

# Copy Supervisor Configuration
COPY *.sv.conf /etc/supervisor/conf.d/

# Copy start script
COPY start.sh /usr/local/bin/start.sh
RUN rm -f /var/log/access.log && mkfifo -m 0666 /var/log/access.log && \
    chmod 755 /usr/local/bin/*

ENV TERM linux
CMD ["/usr/local/bin/start.sh"]
