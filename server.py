import threading
import binascii
import pymongo
import grpc
import sys
import chat_pb2 as chat
import chat_pb2_grpc as rpc
from queue import Queue
from concurrent import futures


class ChitChat(rpc.ChatServicer):  # inheriting here from the protobuf rpc file which is generated

    key_username = 'username'
    key_password = 'password'
    key_data = 'data'
    key = 'key'

    def __init__(self):
        self.setup_db()
        self.q = Queue()
        self.queues = {}
        self.sessions = {}

    def setup_db(self):
        self.store_handlers = {
            chat.StoreRequest.Verb.CREATE: self.store_create,
            chat.StoreRequest.Verb.READ: self.store_read
        }
        db_name = 'users_database'
        table_name = 'users_table'
        db_client = pymongo.MongoClient('mongodb://localhost:27017/')
        # dbs = db_client.list_database_names()
        db = db_client[db_name]
        # tables = db.list_collection_names()
        self.table = db[table_name]

        self.table.drop()  # for testing

    def find(self, username):
        query = {ChitChat.key_username: username}
        return self.table.find_one(query)

    def Register(self, request: chat.AuthRequest, context):
        print('Server: {} {}'.format('register', request.username))
        if self.find(request.username):
            print('Server: found ' + request.username)
            return chat.AuthResponse(ok=False)
        entry = {ChitChat.key_username: request.username, ChitChat.key_password: request.password}
        self.table.insert_one(entry)
        self.queues[request.username] = Queue()
        return self.Login(request, context)

    def Deregister(self, request: chat.Request, context):
        username = self.sessions[request.session]
        print('Server: {} {}'.format('deregister', username))
        query = {ChitChat.key_username: username}
        self.table.delete_one(query)
        self.queues[username] = None
        return chat.Response(ok=True)

    def Login(self, request: chat.AuthRequest, context):
        print('Server: {} {}'.format('login', request.username))
        found = self.find(request.username)
        if not found or (found[ChitChat.key_password] != request.password):
            print('Server: login fail ' + request.username)
            return chat.AuthResponse(ok=False)
        self.sessions[request.username] = request.username
        return chat.AuthResponse(ok=True, session=request.username)

    def Logout(self, request: chat.AuthRequest, context):
        print('Server: {} {}'.format('logout', request.username))
        found = self.find(request.username)
        if not found or (found[ChitChat.key_password] != request.password):
            print('Server: logout fail ' + request.username)
            return chat.AuthResponse(ok=False)
        self.sessions[request.username] = None
        return chat.AuthResponse(ok=True)

    @staticmethod
    def log(action, request):
        print('Server: {} {}'.format(request.session, action))

    def Listen(self, request, context):
        ChitChat.log('listen', request)
        if request.session in self.queues:
            while True:
                data = self.queues[request.session].get()
                yield data
        else:
            print('Server listen: no queue for ' + request.session)

    def Send(self, request: chat.Envelope, context):
        ChitChat.log('send', request)
        if request.recipient in self.queues:
            self.queues[request.recipient].put(request)
            return chat.Response(ok=True)
        else:
            print('Server send: no queue for ' + request.recipient)
            return chat.Response(ok=False)

    def Store(self, request, context):
        username = self.sessions[request.session]
        return self.store_handlers[request.verb](request, username)

    def store_create(self, request, username):
        ChitChat.log('store_create', request)
        for datum in request.data:
            entry = {ChitChat.key_username: username, ChitChat.key: request.key, ChitChat.key_data: datum}
            self.table.insert_one(entry)
        return chat.StoreResponse(ok=True)

    def store_read(self, request, username):
        ChitChat.log('store_read', request)
        query = {ChitChat.key_username: username, ChitChat.key: request.key}
        found = self.table.find(query)
        data = list(map(lambda item: item['data'], found))
        response = chat.StoreResponse(ok=True)
        response.data[:] = data
        return response


class TestClient:

    key_sent = 'sent'
    key_received = 'received'

    def __init__(self, username, password, host):
        self.grpc(host)
        self.register(username, password)
        self.login(username, password)
        self.listen()

    def grpc(self, host):
        channel = grpc.insecure_channel(host + ':' + str(port))
        self.stub = rpc.ChatStub(channel)

    def register(self, username, password):
        request = chat.AuthRequest(username=username, password=password)
        response = self.stub.Register(request)
        if self.check('register', response):
            self.session = response.session

    def deregister(self):
        request = chat.Request(session=self.session)
        response = self.stub.Deregister(request)
        self.check('deregister', response)

    def login(self, username, password):
        request = chat.AuthRequest(username=username, password=password)
        response = self.stub.Login(request)
        if self.check('login', response):
            self.session = response.session

    def check(self, action, response):
        if response.ok:
            return True
        print('Client {}: {} not ok'.format(self.session, action))

    def listen(self):
        threading.Thread(target=self.heard, daemon=True).start()

    def heard(self):
        request = chat.ListenRequest(session=self.session)
        for envelope in self.stub.Listen(request):  # this line will wait for new messages from the server
            print('Client {}: {} says "{}"'.format(self.session, envelope.session, envelope.payload))
            bytes = str.encode(envelope.payload)
            self.store_create(Client.key_received, [bytes])

    def send(self, recipient, text):
        envelope = chat.Envelope(recipient=recipient, payload=text, session=self.session)
        response = self.stub.Send(envelope)
        self.check('send', response)
        bytes = str.encode(text)
        self.store_create(Client.key_sent, [bytes])

    def load_messages(self):
        self.store_read(Client.sent_key)

    def load_messages(self):
        print('Client {}: load_messages'.format(self.session))
        self.store_read(Client.key_sent)
        self.store_read(Client.key_received)

    def store_create(self, key, data):
        request = chat.StoreRequest(verb=chat.StoreRequest.Verb.CREATE, key=key, data=data, session=self.session)
        return self.store(request)

    def store_read(self, key):
        request = chat.StoreRequest(verb=chat.StoreRequest.Verb.READ, key=key, session=self.session)
        response = self.store(request)
        for response_datum in response.data:
            print('Client {}: store_read key={} value={}'.format(self.session, key, response_datum))
        return response

    def store(self, request):
        response = self.stub.Store(request)
        self.check('store', response)
        return response

def test():
    alice = TestClient('alice', 'alicepw', 'localhost')
    bob = TestClient('bob', 'bobpw', 'localhost')
    print('\n')
    alice.store_create('the-key', [b'the-value'])
    alice.store_read('the-key')
    print('\n')
    alice.send('bob', 'hi1')
    alice.send('bob', 'hi2')
    bob.send('alice', 'hi3')
    print('\n')
    alice.load_messages()
    bob.load_messages()
    print('\n')
    alice.deregister()
    bob.deregister()

if __name__ == '__main__':
    port = 11912  # a random port for the server to run on
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))  # create a gRPC server
    rpc.add_ChatServicer_to_server(ChitChat(), server)  # register the server to gRPC
    print('Starting server. Listening on port {}'.format(port))
    server.add_insecure_port('[::]:' + str(port))
    server.start()

    if len(sys.argv) > 1 and sys.argv[1] == 'test':
        test()
    else:
        server.wait_for_termination()
