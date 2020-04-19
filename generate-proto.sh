# generates server and client code from pscrud.proto

#!/bin/bash
echo "Generating proto grpc files..."

echo "-Python"
python -m grpc_tools.protoc -I=. pscrud.proto --python_out=server --grpc_python_out=server

echo "-Swift"
swift_pb_path="client/iosx/ClearKeep/protobuf"
protoc pscrud.proto --swift_out=$swift_pb_path --grpc-swift_out=$swift_pb_path
protoc -I=client chat.proto --swift_out=$swift_pb_path
echo "Done."
