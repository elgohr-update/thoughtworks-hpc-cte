#!/usr/bin/env bash

i=0
while [ $i -lt 3 ]; do
  curl -POST http://172.30.28.8:8086/query -s --data-urlencode "q=DROP DATABASE order_manager"
  curl -POST http://172.30.28.8:8086/query -s --data-urlencode "q=DROP DATABASE trade_manager"

  curl -POST http://172.30.28.8:8086/query -s --data-urlencode "q=CREATE DATABASE order_manager"
  curl -POST http://172.30.28.8:8086/query -s --data-urlencode "q=CREATE DATABASE trade_manager"

  cd bin
  /bin/request_generator_main -n $NUM_OF_REQUEST -f test_env_cte_request_generator_config.json &
  cte_pid=$!
  /bin/request_generator_main -n $NUM_OF_REQUEST -f test_env_akka_request_generator_config.json
  echo '[IMPORTANT] akka-te is finished, waiting for database service'

  while true
  do
    PID_EXIST=$(ps aux | awk '{print $2}'| grep -w $cte_pid)
    if [ ! $PID_EXIST ]
    then
      echo '[IMPORTANT] cte is finished, waiting for database service'
      break
    fi
    echo 'cte is still running, try sleep 5 seconds...'
    sleep 5
  done

  while true
  do
    count1=$(curl -GET 'http://172.30.28.8:8086/query?pretty=true' -s --data-urlencode "db=trade_manager" --data-urlencode "q=SELECT count(*) FROM cte_trades" | python -c 'import json,sys;obj=json.load(sys.stdin); print(obj["results"][0]["series"][0]["values"][0][1])')
    sleep 5
    count2=$(curl -GET 'http://172.30.28.8:8086/query?pretty=true' -s --data-urlencode "db=trade_manager" --data-urlencode "q=SELECT count(*) FROM cte_trades" | python -c 'import json,sys;obj=json.load(sys.stdin); print(obj["results"][0]["series"][0]["values"][0][1])')
    if [ $count1 == $count2 ]
    then
      echo '[IMPORTANT] cte database is available now'
      break
    fi
    echo 'cte database is still busy, try to sleep 5 seconds...'
  done

  while true
  do
    count1=$(curl -GET 'http://172.30.28.8:8086/query?pretty=true' -s --data-urlencode "db=trade_manager" --data-urlencode "q=SELECT count(*) FROM akka_te_trades" | python -c 'import json,sys;obj=json.load(sys.stdin); print(obj["results"][0]["series"][0]["values"][0][1])')
    sleep 5
    count2=$(curl -GET 'http://172.30.28.8:8086/query?pretty=true' -s --data-urlencode "db=trade_manager" --data-urlencode "q=SELECT count(*) FROM akka_te_trades" | python -c 'import json,sys;obj=json.load(sys.stdin); print(obj["results"][0]["series"][0]["values"][0][1])')
    if [ $count1 == $count2 ]
    then
      echo '[IMPORTANT] akka_te database is available now'
      break
    fi
    echo 'akka_te database is still busy, try to sleep 5 seconds...'
  done

  echo '[IMPORTANT] start data_verifier now'
  cd /tmp
  /tmp/data_verifier
  result=$?
  check_result=0
  if [[ $result -eq $check_result ]]
  then
      echo "yeah yeah yeah."
  else
      echo "oh...no"
      break
  fi

  i=$(( i + 1 ))
  echo $i
done
sleep infinity
