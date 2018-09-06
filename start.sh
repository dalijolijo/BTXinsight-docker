#!/bin/bash
set -u

# Downloading bootstrap file
cd /home/bitcore/bitcore-livenet/bin/mynode/data
if [ ! -d /home/bitcore/bitcore-livenet/bin/mynode/data/blocks ] && [ "$(curl -Is https://${WEB}/${BOOTSTRAP} | head -n 1 | tr -d '\r\n')" = "HTTP/1.1 200 OK" ] ; then \
        wget https://${WEB}/${BOOTSTRAP}; \
        tar -xvzf ${BOOTSTRAP}; \
        rm ${BOOTSTRAP}; \
fi

# Starting Supervisor Service
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
