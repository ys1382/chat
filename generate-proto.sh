# generates server and client code from pscrud.proto

#!/bin/bash
echo "Generating proto grpc files..."
echo "-Python"
python -m grpc_tools.protoc -I=. pscrud.proto --python_out=server --grpc_python_out=server
echo "-Swift"
protoc pscrud.proto --swift_out=client/iosx/chat/protobuf --grpc-swift_out=client/iosx/chat/protobuf
protoc -I=client chat.proto --swift_out=client/iosx/chat/protobuf
echo "Done."
