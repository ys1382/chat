# Generated by the gRPC Python protocol compiler plugin. DO NOT EDIT!
"""Client and server classes corresponding to protobuf-defined services."""
import grpc

import pscrud_pb2 as pscrud__pb2


class PscrudStub(object):
    """Missing associated documentation comment in .proto file."""

    def __init__(self, channel):
        """Constructor.

        Args:
            channel: A grpc.Channel.
        """
        self.Register = channel.unary_unary(
                '/grpc.Pscrud/Register',
                request_serializer=pscrud__pb2.AuthRequest.SerializeToString,
                response_deserializer=pscrud__pb2.AuthResponse.FromString,
                )
        self.Login = channel.unary_unary(
                '/grpc.Pscrud/Login',
                request_serializer=pscrud__pb2.AuthRequest.SerializeToString,
                response_deserializer=pscrud__pb2.AuthResponse.FromString,
                )
        self.Authenticate = channel.unary_unary(
                '/grpc.Pscrud/Authenticate',
                request_serializer=pscrud__pb2.Request.SerializeToString,
                response_deserializer=pscrud__pb2.AuthResponse.FromString,
                )
        self.Logout = channel.unary_unary(
                '/grpc.Pscrud/Logout',
                request_serializer=pscrud__pb2.Request.SerializeToString,
                response_deserializer=pscrud__pb2.Response.FromString,
                )
        self.Deregister = channel.unary_unary(
                '/grpc.Pscrud/Deregister',
                request_serializer=pscrud__pb2.Request.SerializeToString,
                response_deserializer=pscrud__pb2.Response.FromString,
                )
        self.Create = channel.unary_unary(
                '/grpc.Pscrud/Create',
                request_serializer=pscrud__pb2.PutRequest.SerializeToString,
                response_deserializer=pscrud__pb2.PutResponse.FromString,
                )
        self.Read = channel.unary_unary(
                '/grpc.Pscrud/Read',
                request_serializer=pscrud__pb2.GetRequest.SerializeToString,
                response_deserializer=pscrud__pb2.GetResponse.FromString,
                )
        self.Update = channel.unary_unary(
                '/grpc.Pscrud/Update',
                request_serializer=pscrud__pb2.PutRequest.SerializeToString,
                response_deserializer=pscrud__pb2.PutResponse.FromString,
                )
        self.Delete = channel.unary_unary(
                '/grpc.Pscrud/Delete',
                request_serializer=pscrud__pb2.GetRequest.SerializeToString,
                response_deserializer=pscrud__pb2.Response.FromString,
                )
        self.Subscribe = channel.unary_unary(
                '/grpc.Pscrud/Subscribe',
                request_serializer=pscrud__pb2.SubscribeRequest.SerializeToString,
                response_deserializer=pscrud__pb2.Response.FromString,
                )
        self.Unsubscribe = channel.unary_unary(
                '/grpc.Pscrud/Unsubscribe',
                request_serializer=pscrud__pb2.SubscribeRequest.SerializeToString,
                response_deserializer=pscrud__pb2.Response.FromString,
                )
        self.Publish = channel.unary_unary(
                '/grpc.Pscrud/Publish',
                request_serializer=pscrud__pb2.PublishRequest.SerializeToString,
                response_deserializer=pscrud__pb2.Response.FromString,
                )
        self.Listen = channel.unary_stream(
                '/grpc.Pscrud/Listen',
                request_serializer=pscrud__pb2.Request.SerializeToString,
                response_deserializer=pscrud__pb2.Publication.FromString,
                )


class PscrudServicer(object):
    """Missing associated documentation comment in .proto file."""

    def Register(self, request, context):
        """Missing associated documentation comment in .proto file."""
        context.set_code(grpc.StatusCode.UNIMPLEMENTED)
        context.set_details('Method not implemented!')
        raise NotImplementedError('Method not implemented!')

    def Login(self, request, context):
        """Missing associated documentation comment in .proto file."""
        context.set_code(grpc.StatusCode.UNIMPLEMENTED)
        context.set_details('Method not implemented!')
        raise NotImplementedError('Method not implemented!')

    def Authenticate(self, request, context):
        """Missing associated documentation comment in .proto file."""
        context.set_code(grpc.StatusCode.UNIMPLEMENTED)
        context.set_details('Method not implemented!')
        raise NotImplementedError('Method not implemented!')

    def Logout(self, request, context):
        """Missing associated documentation comment in .proto file."""
        context.set_code(grpc.StatusCode.UNIMPLEMENTED)
        context.set_details('Method not implemented!')
        raise NotImplementedError('Method not implemented!')

    def Deregister(self, request, context):
        """Missing associated documentation comment in .proto file."""
        context.set_code(grpc.StatusCode.UNIMPLEMENTED)
        context.set_details('Method not implemented!')
        raise NotImplementedError('Method not implemented!')

    def Create(self, request, context):
        """Missing associated documentation comment in .proto file."""
        context.set_code(grpc.StatusCode.UNIMPLEMENTED)
        context.set_details('Method not implemented!')
        raise NotImplementedError('Method not implemented!')

    def Read(self, request, context):
        """Missing associated documentation comment in .proto file."""
        context.set_code(grpc.StatusCode.UNIMPLEMENTED)
        context.set_details('Method not implemented!')
        raise NotImplementedError('Method not implemented!')

    def Update(self, request, context):
        """Missing associated documentation comment in .proto file."""
        context.set_code(grpc.StatusCode.UNIMPLEMENTED)
        context.set_details('Method not implemented!')
        raise NotImplementedError('Method not implemented!')

    def Delete(self, request, context):
        """Missing associated documentation comment in .proto file."""
        context.set_code(grpc.StatusCode.UNIMPLEMENTED)
        context.set_details('Method not implemented!')
        raise NotImplementedError('Method not implemented!')

    def Subscribe(self, request, context):
        """Missing associated documentation comment in .proto file."""
        context.set_code(grpc.StatusCode.UNIMPLEMENTED)
        context.set_details('Method not implemented!')
        raise NotImplementedError('Method not implemented!')

    def Unsubscribe(self, request, context):
        """Missing associated documentation comment in .proto file."""
        context.set_code(grpc.StatusCode.UNIMPLEMENTED)
        context.set_details('Method not implemented!')
        raise NotImplementedError('Method not implemented!')

    def Publish(self, request, context):
        """Missing associated documentation comment in .proto file."""
        context.set_code(grpc.StatusCode.UNIMPLEMENTED)
        context.set_details('Method not implemented!')
        raise NotImplementedError('Method not implemented!')

    def Listen(self, request, context):
        """Missing associated documentation comment in .proto file."""
        context.set_code(grpc.StatusCode.UNIMPLEMENTED)
        context.set_details('Method not implemented!')
        raise NotImplementedError('Method not implemented!')


def add_PscrudServicer_to_server(servicer, server):
    rpc_method_handlers = {
            'Register': grpc.unary_unary_rpc_method_handler(
                    servicer.Register,
                    request_deserializer=pscrud__pb2.AuthRequest.FromString,
                    response_serializer=pscrud__pb2.AuthResponse.SerializeToString,
            ),
            'Login': grpc.unary_unary_rpc_method_handler(
                    servicer.Login,
                    request_deserializer=pscrud__pb2.AuthRequest.FromString,
                    response_serializer=pscrud__pb2.AuthResponse.SerializeToString,
            ),
            'Authenticate': grpc.unary_unary_rpc_method_handler(
                    servicer.Authenticate,
                    request_deserializer=pscrud__pb2.Request.FromString,
                    response_serializer=pscrud__pb2.AuthResponse.SerializeToString,
            ),
            'Logout': grpc.unary_unary_rpc_method_handler(
                    servicer.Logout,
                    request_deserializer=pscrud__pb2.Request.FromString,
                    response_serializer=pscrud__pb2.Response.SerializeToString,
            ),
            'Deregister': grpc.unary_unary_rpc_method_handler(
                    servicer.Deregister,
                    request_deserializer=pscrud__pb2.Request.FromString,
                    response_serializer=pscrud__pb2.Response.SerializeToString,
            ),
            'Create': grpc.unary_unary_rpc_method_handler(
                    servicer.Create,
                    request_deserializer=pscrud__pb2.PutRequest.FromString,
                    response_serializer=pscrud__pb2.PutResponse.SerializeToString,
            ),
            'Read': grpc.unary_unary_rpc_method_handler(
                    servicer.Read,
                    request_deserializer=pscrud__pb2.GetRequest.FromString,
                    response_serializer=pscrud__pb2.GetResponse.SerializeToString,
            ),
            'Update': grpc.unary_unary_rpc_method_handler(
                    servicer.Update,
                    request_deserializer=pscrud__pb2.PutRequest.FromString,
                    response_serializer=pscrud__pb2.PutResponse.SerializeToString,
            ),
            'Delete': grpc.unary_unary_rpc_method_handler(
                    servicer.Delete,
                    request_deserializer=pscrud__pb2.GetRequest.FromString,
                    response_serializer=pscrud__pb2.Response.SerializeToString,
            ),
            'Subscribe': grpc.unary_unary_rpc_method_handler(
                    servicer.Subscribe,
                    request_deserializer=pscrud__pb2.SubscribeRequest.FromString,
                    response_serializer=pscrud__pb2.Response.SerializeToString,
            ),
            'Unsubscribe': grpc.unary_unary_rpc_method_handler(
                    servicer.Unsubscribe,
                    request_deserializer=pscrud__pb2.SubscribeRequest.FromString,
                    response_serializer=pscrud__pb2.Response.SerializeToString,
            ),
            'Publish': grpc.unary_unary_rpc_method_handler(
                    servicer.Publish,
                    request_deserializer=pscrud__pb2.PublishRequest.FromString,
                    response_serializer=pscrud__pb2.Response.SerializeToString,
            ),
            'Listen': grpc.unary_stream_rpc_method_handler(
                    servicer.Listen,
                    request_deserializer=pscrud__pb2.Request.FromString,
                    response_serializer=pscrud__pb2.Publication.SerializeToString,
            ),
    }
    generic_handler = grpc.method_handlers_generic_handler(
            'grpc.Pscrud', rpc_method_handlers)
    server.add_generic_rpc_handlers((generic_handler,))


 # This class is part of an EXPERIMENTAL API.
class Pscrud(object):
    """Missing associated documentation comment in .proto file."""

    @staticmethod
    def Register(request,
            target,
            options=(),
            channel_credentials=None,
            call_credentials=None,
            compression=None,
            wait_for_ready=None,
            timeout=None,
            metadata=None):
        return grpc.experimental.unary_unary(request, target, '/grpc.Pscrud/Register',
            pscrud__pb2.AuthRequest.SerializeToString,
            pscrud__pb2.AuthResponse.FromString,
            options, channel_credentials,
            call_credentials, compression, wait_for_ready, timeout, metadata)

    @staticmethod
    def Login(request,
            target,
            options=(),
            channel_credentials=None,
            call_credentials=None,
            compression=None,
            wait_for_ready=None,
            timeout=None,
            metadata=None):
        return grpc.experimental.unary_unary(request, target, '/grpc.Pscrud/Login',
            pscrud__pb2.AuthRequest.SerializeToString,
            pscrud__pb2.AuthResponse.FromString,
            options, channel_credentials,
            call_credentials, compression, wait_for_ready, timeout, metadata)

    @staticmethod
    def Authenticate(request,
            target,
            options=(),
            channel_credentials=None,
            call_credentials=None,
            compression=None,
            wait_for_ready=None,
            timeout=None,
            metadata=None):
        return grpc.experimental.unary_unary(request, target, '/grpc.Pscrud/Authenticate',
            pscrud__pb2.Request.SerializeToString,
            pscrud__pb2.AuthResponse.FromString,
            options, channel_credentials,
            call_credentials, compression, wait_for_ready, timeout, metadata)

    @staticmethod
    def Logout(request,
            target,
            options=(),
            channel_credentials=None,
            call_credentials=None,
            compression=None,
            wait_for_ready=None,
            timeout=None,
            metadata=None):
        return grpc.experimental.unary_unary(request, target, '/grpc.Pscrud/Logout',
            pscrud__pb2.Request.SerializeToString,
            pscrud__pb2.Response.FromString,
            options, channel_credentials,
            call_credentials, compression, wait_for_ready, timeout, metadata)

    @staticmethod
    def Deregister(request,
            target,
            options=(),
            channel_credentials=None,
            call_credentials=None,
            compression=None,
            wait_for_ready=None,
            timeout=None,
            metadata=None):
        return grpc.experimental.unary_unary(request, target, '/grpc.Pscrud/Deregister',
            pscrud__pb2.Request.SerializeToString,
            pscrud__pb2.Response.FromString,
            options, channel_credentials,
            call_credentials, compression, wait_for_ready, timeout, metadata)

    @staticmethod
    def Create(request,
            target,
            options=(),
            channel_credentials=None,
            call_credentials=None,
            compression=None,
            wait_for_ready=None,
            timeout=None,
            metadata=None):
        return grpc.experimental.unary_unary(request, target, '/grpc.Pscrud/Create',
            pscrud__pb2.PutRequest.SerializeToString,
            pscrud__pb2.PutResponse.FromString,
            options, channel_credentials,
            call_credentials, compression, wait_for_ready, timeout, metadata)

    @staticmethod
    def Read(request,
            target,
            options=(),
            channel_credentials=None,
            call_credentials=None,
            compression=None,
            wait_for_ready=None,
            timeout=None,
            metadata=None):
        return grpc.experimental.unary_unary(request, target, '/grpc.Pscrud/Read',
            pscrud__pb2.GetRequest.SerializeToString,
            pscrud__pb2.GetResponse.FromString,
            options, channel_credentials,
            call_credentials, compression, wait_for_ready, timeout, metadata)

    @staticmethod
    def Update(request,
            target,
            options=(),
            channel_credentials=None,
            call_credentials=None,
            compression=None,
            wait_for_ready=None,
            timeout=None,
            metadata=None):
        return grpc.experimental.unary_unary(request, target, '/grpc.Pscrud/Update',
            pscrud__pb2.PutRequest.SerializeToString,
            pscrud__pb2.PutResponse.FromString,
            options, channel_credentials,
            call_credentials, compression, wait_for_ready, timeout, metadata)

    @staticmethod
    def Delete(request,
            target,
            options=(),
            channel_credentials=None,
            call_credentials=None,
            compression=None,
            wait_for_ready=None,
            timeout=None,
            metadata=None):
        return grpc.experimental.unary_unary(request, target, '/grpc.Pscrud/Delete',
            pscrud__pb2.GetRequest.SerializeToString,
            pscrud__pb2.Response.FromString,
            options, channel_credentials,
            call_credentials, compression, wait_for_ready, timeout, metadata)

    @staticmethod
    def Subscribe(request,
            target,
            options=(),
            channel_credentials=None,
            call_credentials=None,
            compression=None,
            wait_for_ready=None,
            timeout=None,
            metadata=None):
        return grpc.experimental.unary_unary(request, target, '/grpc.Pscrud/Subscribe',
            pscrud__pb2.SubscribeRequest.SerializeToString,
            pscrud__pb2.Response.FromString,
            options, channel_credentials,
            call_credentials, compression, wait_for_ready, timeout, metadata)

    @staticmethod
    def Unsubscribe(request,
            target,
            options=(),
            channel_credentials=None,
            call_credentials=None,
            compression=None,
            wait_for_ready=None,
            timeout=None,
            metadata=None):
        return grpc.experimental.unary_unary(request, target, '/grpc.Pscrud/Unsubscribe',
            pscrud__pb2.SubscribeRequest.SerializeToString,
            pscrud__pb2.Response.FromString,
            options, channel_credentials,
            call_credentials, compression, wait_for_ready, timeout, metadata)

    @staticmethod
    def Publish(request,
            target,
            options=(),
            channel_credentials=None,
            call_credentials=None,
            compression=None,
            wait_for_ready=None,
            timeout=None,
            metadata=None):
        return grpc.experimental.unary_unary(request, target, '/grpc.Pscrud/Publish',
            pscrud__pb2.PublishRequest.SerializeToString,
            pscrud__pb2.Response.FromString,
            options, channel_credentials,
            call_credentials, compression, wait_for_ready, timeout, metadata)

    @staticmethod
    def Listen(request,
            target,
            options=(),
            channel_credentials=None,
            call_credentials=None,
            compression=None,
            wait_for_ready=None,
            timeout=None,
            metadata=None):
        return grpc.experimental.unary_stream(request, target, '/grpc.Pscrud/Listen',
            pscrud__pb2.Request.SerializeToString,
            pscrud__pb2.Publication.FromString,
            options, channel_credentials,
            call_credentials, compression, wait_for_ready, timeout, metadata)
