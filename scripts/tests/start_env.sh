#!/usr/bin/env bash

set -e

PROJECT_DIR=$(git rev-parse --show-toplevel)

BIN="${PROJECT_DIR}/target/debug/comit-scripts"

## Start tests
echo "Running $0"

$BIN start-env > /dev/null &
PID=$!

TIMEOUT=300
TEST_PASSED=false

# Count the number of containers
function check_containers() {
  ERROR=false
  for CONTAINER in ethereum bitcoin cnd_0 cnd_1; do
    NUM=$(docker ps -qf name=${CONTAINER} |wc -l)
    if test "$NUM" -ne 1; then
      ERROR=true;
      break;
    fi
  done
  $ERROR && echo 1 || echo 0
}

while [ $TIMEOUT -gt 0 ]; do
    if [ "$(check_containers)" -eq 0 ]; then
      TEST_PASSED=true;
      TIMEOUT=0
    else
      sleep 1;
      TIMEOUT=$((TIMEOUT-1));
    fi
done

kill -s SIGINT $PID;
wait $PID;

if ! $TEST_PASSED; then
  echo "FAIL: ${CONTAINER} docker container was not started.";
  exit 1;
else
  echo "SUCCESS: Docker containers were started.";
  exit 0;
fi
