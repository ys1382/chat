import os
import grpc
import threading
import pscrud_pb2 as pscrud
import pscrud_pb2_grpc as rpc
from concurrent import futures

import server

class TestClient:

    key_sent = 'sent'
    key_received = 'received'

    def __init__(self, username, password, host, port):
        self.username = username
        self.stub = self.grpc(host, port)
        self.session = self.register(username, password)
        self.session = self.login(username, password)
        self.listen()

    def grpc(self, host, port):
        channel = grpc.insecure_channel(host + ':' + str(port))
        return rpc.PscrudStub(channel)

    def register(self, username, password):
        request = pscrud.AuthRequest(username=username, password=password)
        response = self.stub.Register(request)
        if self.check('register', response):
            return response.session

    def deregister(self):
        request = pscrud.Request(session=self.session)
        response = self.stub.Deregister(request)
        self.check('deregister', response)

    def login(self, username, password):
        request = pscrud.AuthRequest(username=username, password=password)
        response = self.stub.Login(request)
        if self.check('login', response):
            return response.session

    def check(self, action, response):
        if response.ok:
            return True
        print('TestClient {}: {} not ok'.format(self.username, action))

    def listen(self):
        threading.Thread(target=self.heard, daemon=True).start()

    def heard(self):
        request = pscrud.Request(session=self.session)
        for publication in self.stub.Listen(request):  # this line will wait for new messages from the server
            print('TestClient {}: heard on topic {}: {}'.format(self.session, publication.topic, publication.data))
            # bytes = str.encode(publication.data)
            self.create(TestClient.key_received, publication.data)

    def create(self, key, data):
        request = pscrud.PutRequest(key=key, data=data, session=self.session)
        response = self.stub.Create(request)
        self.check('create', response)

    def read(self, key, row_id):
        request = pscrud.GetRequest(key=key, id=row_id, session=self.session)
        response = self.stub.Read(request)
        for response_datum in response.data:
            print('TestClient {}: read key={} value={}'.format(self.session, key, response_datum))
        return response

    def update(self, key, row_id, data):
        request = pscrud.PutRequest(key=key, id=row_id, data=data, session=self.session)
        response = self.stub.Update(request)
        self.check('update', response)

    def delete(self, key, row_id):
        request = pscrud.GetRequest(key=key, id=row_id, session=self.session)
        response = self.stub.Delete(request)
        self.check('delete', response)

    def subscribe(self, topic):
        request = pscrud.SubscribeRequest(topic=topic, session=self.session)
        response = self.stub.Subscribe(request)
        self.check('subscribe', response)

    def publish(self, topic, data):
        print('TestClient {} publish {} to topic {}'.format(self.username, data, topic))
        request = pscrud.PublishRequest(topic=topic, data=data, session=self.session)
        response = self.stub.Publish(request)
        self.check('publish', response)

def test_clients(port):
    alice = TestClient('alice', 'alicepw', 'localhost', port)
    bob = TestClient('bob', 'bobpw', 'localhost', port)
    print('')

    # pub-sub
    alice_subscription = "alice-subscription"
    alice.subscribe(alice_subscription)
    bob_subscription = "bob-subscription"
    bob.subscribe(bob_subscription)
    alice.publish(bob_subscription, b'alice-publication-to-bob')
    print('')

    # CRUD
    alice.create('the-key', b'the-value1')
    alice.read('the-key', None)
    alice.update('the-key', None, b'the-value2')
    alice.delete('the-key', None)
    print('')

    alice.deregister()
    bob.deregister()
    print('\nDone')
    os._exit(0)

def test_main():
    port = 11912
    grpc_server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))  # create a gRPC server
    rpc.add_PscrudServicer_to_server(server.Pscrud(), grpc_server) # register the server with gRPC
    print('Starting server. Listening on port {}'.format(port))
    grpc_server.add_insecure_port('[::]:' + str(port))
    grpc_server.start()

    test_clients(port)
    grpc_server.wait_for_termination()

if __name__ == '__main__':
    test_main()
