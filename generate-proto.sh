#!/bin/bash
echo "Generating proto grpc files..."
echo "-Python"
python -m grpc_tools.protoc -I=. --python_out=. --grpc_python_out=. chat.proto
echo "-Swift"
protoc --swift_out=ios/chat chat.proto --grpc-swift_out=ios/chat
echo "Done."
