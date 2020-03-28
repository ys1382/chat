import pymongo
import grpc
import chat_pb2 as chat
import chat_pb2_grpc as rpc
from queue import Queue


class ChitChat(rpc.ChatServicer):  # inheriting here from the protobuf rpc file which is generated

    key_username = 'username'
    key_password = 'password'
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
        query = {ChitChat.key_username: username}
        return self.table.find_one(query)

    def Register(self, request: chat.AuthRequest, context):
        print('Server: {} {}'.format('register', request.username))
        if self.find(request.username):
            print('Server: found ' + request.username)
            return chat.AuthResponse(ok=False)
        entry = {ChitChat.key_username: request.username, ChitChat.key_password: request.password}
        self.table.insert_one(entry)
        return self.Login(request, context)

    def Deregister(self, request: chat.Request, context):
        username = self.sessions[request.session]
        if not username:
            print('Server Deregister: session {} not found'.format(request.session))
            return chat.Response(ok=False)
        print('Server: {} {}'.format('deregister', username))
        query = {ChitChat.key_username: username}
        self.table.delete_one(query)
        self.queues[username] = None
        return chat.Response(ok=True)

    def Login(self, request: chat.AuthRequest, context):
        print('Server: {} {}'.format('login', request.username))
        found = self.find(request.username)
        if not found:
            print('Server: login fail -- {} not found'.format(request.username))
        if found and (found[ChitChat.key_password] != request.password):
            print('Server: login fail {} is not {}'.format(request.username, found[ChitChat.key_password]))
        if not found or (found[ChitChat.key_password] != request.password):
            return chat.AuthResponse(ok=False)
        self.sessions[request.username] = request.username
        self.queues[request.username] = Queue()
        self.subscriptions[request.username] = []
        return chat.AuthResponse(ok=True, session=request.username)

    def Logout(self, request: chat.AuthRequest, context):
        print('Server: {} {}'.format('logout', request.username))
        found = self.find(request.username)
        if not found or (found[ChitChat.key_password] != request.password):
            print('Server: logout fail ' + request.username)
            return chat.AuthResponse(ok=False)
        self.sessions[request.username] = None
        return chat.AuthResponse(ok=True)

    def Authenticate(self, request, context):
        print('Server: {} {}'.format('authenticate', request.session))
        self.sessions[request.session] = request.session
        self.queues[request.session] = Queue()
        return chat.Response(ok=True)

    @staticmethod
    def log(action, request):
        print('Server: {} {}'.format(request.session, action))

    def Listen(self, request, context):
        ChitChat.log('listen', request)
        username = self.sessions[request.session]
        if not username:
            print('Server Listen: session {} not found'.format(request.session))
            return chat.Response(ok=False)
        if username in self.queues:
            while True:
                publish_request = self.queues[request.session].get() # blocking until the next .put for this queue
                print('{} q.get {} for topic {}'.format(username, publish_request.data, publish_request.topic))
                publication = chat.Publication(topic=publish_request.topic, data=publish_request.data)
                yield publication
        else:
            print('Server listen: no subscription queue for ' + request.session)

    def Subscribe(self, request, context):
        ChitChat.log('subscribe', request)
        if request.topic not in self.subscriptions:
            self.subscriptions[request.topic] = set()
        username = self.sessions[request.session]
        if not username:
            print('Server Subscribe: username {} not found'.format(username))
            return chat.Response(ok=False)
        self.subscriptions[request.topic].add(username)
        return chat.Response(ok=True)

    def Unsubscribe(self, request, context):
        ChitChat.log('subscribe', request)
        username = self.sessions[request.session]
        if not username:
            print('Server Unsubscribe: session {} not found'.format(request.session))
            return chat.Response(ok=False)
        subscribers = self.subscriptions[request.topic] if request.topic in self.subscriptions else None
        if not username:
            print('unsubscribe: {} not found for session {}'.format(username, request.session))
            return chat.Response(ok=False)
        if request.topic not in self.subscriptions:
            print('unsubscribe: topic {} not found'.format(request.topic))
            return chat.Response(ok=False)
        if username not in self.subscriptions[request.topic]:
            print('unsubscribe: username {} not subscribed to topic'.format(username, request.topic))
            return chat.Response(ok=False)
        # phew!
        subscribers.remove(username)
        return chat.Response(ok=True)

    # find all subscribers for the topic and put in their queues
    def Publish(self, request: chat.PublishRequest, context):
        ChitChat.log('publish', request)
        subscribers = self.subscriptions[request.topic]
        print('Server publish: subscribers={}'.format(subscribers))
        if not subscribers:
            print('Server publish: no subscribers for ' + request.topic)
            return chat.Response(ok=true) # publication is still ok
        for subscriber in subscribers:
            if subscriber in self.queues:
                self.queues[subscriber].put(request)
                return chat.Response(ok=True)
            else:
                print('Server publish: no queue for {} in {}'.format(subscriber, self.queues.keys()))
                return chat.Response(ok=False)

    def Create(self, request: chat.PutRequest, context):
        username = self.sessions[request.session]
        if not username:
            print('Server Create: session {} not found'.format(request.session))
            return chat.PutResponse(ok=False)
        entry = {ChitChat.key_username: username, ChitChat.key: request.key, ChitChat.key_data: request.data}
        inserted_id = self.table.insert_one(entry).inserted_id
        return chat.PutResponse(ok=True, id=str(inserted_id))

    def Read(self, request: chat.GetRequest, context):
        try:
            query, username = self.find_query(request)
        except KeyError:
            return chat.GetResponse(ok=False)
        print('Server Read: query={}'.format(query))
        found = self.table.find(query)
        data = list(map(lambda item: chat.Datum(data=item['data']), found))
        response = chat.GetResponse(ok=True, data=data)
        return response

    def Update(self, request: chat.PutRequest, context):
        try:
            query, username = self.find_query(request)
        except KeyError:
            return chat.PutResponse(ok=False)
        entry = { "$set": {ChitChat.key_username: username, ChitChat.key: request.key, ChitChat.key_data: request.data}}
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
            return {ChitChat.key_username: username, ChitChat.key: request.key}, username

def server_main():
    port = 11912
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))  # create a gRPC server
    rpc.add_ChatServicer_to_server(ChitChat(), server) # register the server with gRPC
    print('Starting server. Listening on port {}'.format(port))
    server.add_insecure_port('[::]:' + str(port))
    server.start()
    server.wait_for_termination()

if __name__ == '__main__':
    server_main()
