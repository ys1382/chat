import SwiftUI

struct DetailView: View {

    private let selectedRoom: String
    @State private var nextMessage: String = ""
//    @ObservedObject var resource = Backend.shared
    @ObservedObject var resource = BackendTink.shared
    
    init(room: String) {
        selectedRoom = room
    }

    var body: some View {
        
//        print(resource.messages)
        
        return VStack {
//            List(resource.messages, rowContent: PostView.init)
            List(resource.messages, id: \.newID) { landmark in
                PostView(postModel: landmark)
            }
                .navigationBarTitle(Text(self.selectedRoom))
            HStack {
                TextFieldContent(key: "Next message", value: self.$nextMessage)
                Button( action: {
                    self.send()
                }){
                    Image(systemName: "paperplane")
                }.padding(.trailing)
            }
            
        }.onAppear() {
            self.resource.messages.removeAll()
        }
    }

    private func send() {
        
        guard let payload = $nextMessage.wrappedValue.data(using: .utf8) else {
            return
        }
        
        let envelope : Chat_Envelope = .with {
            $0.from = Backend.shared.authenticator.username!
            $0.to = self.selectedRoom
            $0.payload = payload
        }
        
        let chit: Chat_Chit = .with {
            $0.what = .envelope
            $0.envelope = envelope
        }
        
        let post = PostModel(id: "", envelope: chit.envelope, from: envelope.from)
//        Backend.shared.messages.append(post)
//
//        Backend.shared.send(nextMessage,
//                            to: self.selectedRoom) { success, error in
//            print("DetailView sent: success=\(success), error=\(String(describing: error))")
//        }
        
        BackendTink.shared.messages.append(post)
        
        BackendTink.shared.send(nextMessage,
                            to: self.selectedRoom) { success, error in
            print("DetailView sent: success=\(success), error=\(String(describing: error))")
        }
        
        nextMessage = "" //-- clear input text
    }
}

struct PostView: View {
    var postModel: PostModel

    var body: some View {
        
//        let checkSender = postModel.from == Backend.shared.authenticator.username!
        let checkSender = postModel.from == BackendTink.shared.authenticator.username!
        
        if checkSender {
            
            let senderView: HStack = HStack(alignment: .top, spacing: 8) {
                Text(sender()).bold().foregroundColor(Color.red)
                Text(stringValue()).alignmentGuide(.trailing) { d in
                    d[.leading]
                }
            }
            
            return senderView
            
        } else {
            
            let receiveView: HStack = HStack(alignment: .top, spacing: 8) {
                Text(sender()).bold().foregroundColor(Color.green)
                Text(stringValue()).alignmentGuide(.trailing) { d in
                    d[.trailing]
                }
            }
            
            return receiveView
        }
    }

    private func stringValue() -> String {
        return String(data: postModel.envelope.payload, encoding: .utf8) ?? "x"
    }
    
    private func sender() -> String {
        return postModel.envelope.from
    }
}

// https://swiftui-lab.com/bug-navigationlink-isactive/
struct MyBackButton: View {
    let label: String
    let closure: () -> ()

    var body: some View {
        Button(action: { self.closure() }) {
            HStack {
                Image(systemName: "chevron.left")
                Text(label)
            }
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(room: "A Room with a View")
    }
}
