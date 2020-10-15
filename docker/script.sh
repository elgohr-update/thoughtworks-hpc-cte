#!/usr/bin/env bash

echo "running on host: $HOST"
echo "seeds: $SEEDS"
NAME=${NAME:-$HOST}
echo "name: ${NAME}"

echo /bin/node_keeper --name=$NAME --seeds=$SEEDS --host=$HOST --port=4445 $LOG_COMMANDS --role=$ROLE --app=$APP  --app-args="${APP_ARGS}"
/bin/node_keeper --name=$NAME --seeds=$SEEDS --host=$HOST --port=4445 $LOG_COMMANDS --role=$ROLE --app=$APP  --app-args="${APP_ARGS}"