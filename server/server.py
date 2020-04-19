import pymongo
import grpc
import pscrud_pb2 as chat
import pscrud_pb2_grpc as rpc
from queue import Queue
from concurrent import futures


class Pscrud(rpc.PscrudServicer):# inherits from the protobuf rpc file which is generated

    key_username = 'username'
    key_password = 'password'
    key_publication = 'publication'
    key_data = 'data'
    key = 'key'

    def __init__(self):
        self.table = self.setup_db()
        self.q = Queue()
        self.queues = {} # maps username to queue
        self.subscriptions = {}  # maps topics to usernames
        self.sessions = {} # maps session to username

    @staticmethod
    def setup_db():
        db_name = 'users_database'
        table_name = 'users_table'
        db_client = pymongo.MongoClient('mongodb://localhost:27017/')
        db = db_client[db_name]

        db[table_name].drop()  # for testing

        return db[table_name]

    def find(self, username):
        query = {Pscrud.key_username: username}
        return self.table.find_one(query)

    def Register(self, request: chat.AuthRequest, context):
        print('Server: {} {}'.format('register', request.username))
        if self.find(request.username):
            print('Server: found ' + request.username)
            return chat.AuthResponse(ok=False)
        entry = {Pscrud.key_username: request.username, Pscrud.key_password: request.password}
        self.table.insert_one(entry)
        return self.Login(request, context)

    def Deregister(self, request: chat.Request, context):
        username = self.sessions[request.session]
        if not username:
            print('Server Deregister: session {} not found'.format(request.session))
            return chat.Response(ok=False)
        print('Server: {} {}'.format('deregister', username))
        query = {Pscrud.key_username: username}
        self.table.delete_one(query)
        self.queues[username] = None
        return chat.Response(ok=True)

    def Login(self, request: chat.AuthRequest, context):
        print('Server: {} {}'.format('login', request.username))
        found = self.find(request.username)
        if not found:
            print('Server: login fail -- {} not found'.format(request.username))
        if found and (found[Pscrud.key_password] != request.password):
            print('Server: login fail {} is not {}'.format(request.username, found[Pscrud.key_password]))
        if not found or (found[Pscrud.key_password] != request.password):
            return chat.AuthResponse(ok=False)
        self.sessions[request.username] = request.username
        self.queues[request.username] = Queue()
        self.subscriptions[request.username] = set()
        print('Server: login success for {}'.format(request.username))
        return chat.AuthResponse(ok=True, session=request.username)

    def Logout(self, request: chat.AuthRequest, context):
        print('Server: {} {}'.format('logout', request.session))
        found = self.find(request.session)
        if not found or (found[Pscrud.key_password] != request.password):
            print('Server: logout fail ' + request.session)
            return chat.AuthResponse(ok=False)
        self.sessions[request.session] = None
        return chat.AuthResponse(ok=True)

    def Authenticate(self, request, context):
        print('Server: {} {}'.format('authenticate', request.session))
        self.sessions[request.session] = request.session
        username = self.sessions[request.session]
        if not username:
            print('Server Authenticate: session {} not found'.format(request.session))
            return chat.Response(ok=False)
        self.subscriptions[username] = set()
        self.queues[request.session] = Queue()
        return chat.Response(ok=True)

    @staticmethod
    def log(action, request=None):
        session = (request.session + ' ') if request else ''
        print('Server: {}{}'.format(session, action))

    def Listen(self, request, context):
        Pscrud.log('listen', request)
        username = self.sessions[request.session]
        if not username:
            print('Server Listen: session {} not found'.format(request.session))
            return chat.Response(ok=False)
        if username in self.queues:
            while True:
                publication = self.queues[request.session].get() # blocking until the next .put for this queue
                print('Server listen: {} q.get {} for topic {}'.format(username, publication.data, publication.topic))
                yield publication
        else:
            print('Server listen: no subscription queue for ' + request.session)

    def Subscribe(self, request, context):
        Pscrud.log('subscribe', request)
        username = self.sessions[request.session]
        if not username:
            print('Server subscribe: session {} not found'.format(request.session))
            return chat.Response(ok=False)
        print('Server subscribe: username={}'.format(username))
        print('Server subscribe: subscriptions={}'.format(self.subscriptions))
        if request.topic not in self.subscriptions:
            print('subscriptions new topic {}'.format(request.topic))
            self.subscriptions[request.topic] = set()
        print('subscriptions add {} for {}'.format(request.topic, username))
        self.subscriptions[request.topic].add(username)
        print('subscriptions done: {}'.format(self.subscriptions))
        return chat.Response(ok=True)

    def Unsubscribe(self, request, context):
        Pscrud.log('subscribe', request)
        username = self.sessions[request.session]
        if not username:
            print('Server Unsubscribe: session {} not found'.format(request.session))
            return chat.Response(ok=False)
        if request.topic not in self.subscriptions:
            print('Server unsubscribe: topic {} not found'.format(request.topic))
            return chat.Response(ok=False)
        if username not in self.subscriptions[request.topic]:
            print('Server unsubscribe: username {} not subscribed to topic'.format(username, request.topic))
            return chat.Response(ok=False)
        subscribers = self.subscriptions[request.topic] if request.topic in self.subscriptions else None
        # phew!
        subscribers.remove(username)
        return chat.Response(ok=True)

    # find all subscribers for the topic and put in their queues
    def Publish(self, request: chat.PublishRequest, context):
        Pscrud.log('publish', request)
        if request.topic not in self.subscriptions:
            print('Server publish: topic {} not found'.format(request.topic))
            return chat.Response(ok=False)
        subscribers = self.subscriptions[request.topic]
        print('Server publish: subscribers={}'.format(subscribers))
        if not subscribers:
            print('Server publish: no subscribers for ' + request.topic)
            return chat.Response(ok=true)

        for subscriber in subscribers:
            print('Server publish: subscriber = {}'.format(subscriber))
            if subscriber in self.queues:
                publication = chat.Publication(topic=request.topic, data=request.data)
                publication.id = self.store(subscriber, publication.data)
                self.queues[subscriber].put(publication)
                print('Server put')
            else:
                print('Server publish: no queue for {} in {}'.format(subscriber, self.queues.keys()))

        print('Server published')
        return chat.Response(ok=True)

    def store(self, subscriber, data):
        print('Server store for {}: {}'.format(subscriber, data))
        entry = {Pscrud.key_username: subscriber, Pscrud.key: Pscrud.key_publication, Pscrud.key_data: data}
        id = str(self.table.insert_one(entry).inserted_id)
        print('Server stored id=' + id)
        return id

    def Create(self, request: chat.PutRequest, context):
        username = self.sessions[request.session]
        if not username:
            print('Server Create: session {} not found'.format(request.session))
            return chat.PutResponse(ok=False)
        entry = {Pscrud.key_username: username, Pscrud.key: request.key, Pscrud.key_data: request.data}
        inserted_id = self.table.insert_one(entry).inserted_id
        print('Server Create: data={}'.format(request.data))
        return chat.PutResponse(ok=True, id=str(inserted_id))

    def Read(self, request: chat.GetRequest, context):
        try:
            query, username = self.find_query(request)
        except KeyError:
            print('Server Read KeyError')
            return chat.GetResponse(ok=False)
        print('Server Read: query={}'.format(query))
        found = list(self.table.find(query))
        print('Server Read: found={}'.format(found))
        ids = list(map(lambda item: str(item['_id']), found))
        print('Server Read: ids={}'.format(ids))
        data = list(map(lambda item: chat.Datum(id=str(item['_id']), data=item['data']), found))
        print('Server Read: data={}'.format(data))
        response = chat.GetResponse(ok=True, data=data)
        return response

    def Update(self, request: chat.PutRequest, context):
        try:
            query, username = self.find_query(request)
        except KeyError:
            return chat.PutResponse(ok=False)
        entry = { "$set": {Pscrud.key_username: username, Pscrud.key: request.key, Pscrud.key_data: request.data}}
        self.table.update_one(query, entry)
        return chat.Response(ok=True)

    def Delete(self, request: chat.GetRequest, context):
        try:
            query, username = self.find_query(request)
        except KeyError:
            return chat.Response(ok=False)
        self.table.delete_one(query)
        return chat.Response(ok=True)

    def find_query(self, request: chat.GetRequest):
        username = self.sessions[request.session]
        if not username:
            raise KeyError('Server find_query: session {} not found'.format(request.session))
        if request.id:
            return {"_id": ObjectId(request.id)}, username
        else:
            return {Pscrud.key_username: username, Pscrud.key: request.key}, username

def server_main():
    port = 11912
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))  # create a gRPC server
    rpc.add_PscrudServicer_to_server(Pscrud(), server) # register the server with gRPC
    print('Starting server. Listening on port {}'.format(port))
    server.add_insecure_port('[::]:' + str(port))
    server.start()
    server.wait_for_termination()

if __name__ == '__main__':
    server_main()
