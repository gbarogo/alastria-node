#!/bin/bash

set -e

CONSTELLATION=${ENABLE_CONSTELLATION:-}

mapfile -t NODE_TYPE <~/alastria/data/NODE_TYPE

if [ -e ~/alastria-node/data/PID_Cron ]; then
    ./stop_cron.sh
fi

if [ "$NODE_TYPE" == "general" ] && [ ! -z "$CONSTELLATION" ]; then
    pkill -f constellation-node
fi

pkill -f geth

set +e
