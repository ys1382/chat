import SwiftUI

struct DetailView: View {

    private let selectedRoom: String
    @State private var nextMessage: String = ""
    @ObservedObject var resource = Backend.shared
    
    init(room: String) {
        selectedRoom = room
    }

    var body: some View {
        VStack {
//            List(resource.messages, rowContent: PostView.init)
            List(resource.messages, id: \.id) { landmark in
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
        }
    }

    private func send() {
        guard let payload = nextMessage.data(using: .utf8) else {
            print("Could not stringify \(nextMessage)")
            return
        }
        Backend.shared.sendToPeer(recipient: self.selectedRoom,
                                  payload: payload) { success, error in
            print("DetailView sent: success=\(success), error=\(String(describing: error))")
        }
    }
}

struct PostView: View {
    var postModel: PostModel

    var body: some View {
        VStack(alignment: .leading) {
            Text(stringValue()).bold()
        }
    }

    private func stringValue() -> String {
        return String(data: postModel.envelope.payload, encoding: .utf8) ?? "x"
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
