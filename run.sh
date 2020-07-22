#!/bin/sh

RUN_DIR=/Users/reasonamu/Desktop/chat/server
echo $RUN_DIR

echo "Run server"
source ${RUN_DIR}/venv/bin/activate
python3 ${RUN_DIR}/server.py
echo "Running ..."
