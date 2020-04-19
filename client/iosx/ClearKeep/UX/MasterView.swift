import SwiftUI

struct MasterView: View {

    @ObservedObject var resource = Backend.shared

    var body: some View {
        Group {
            List {
                ForEach(resource.rooms, id: \.self) { room in
                    NavigationLink(
                        destination: DetailView(room: room.id)
                    ) {
                        Text(room.id)
                    }
                }.onDelete { indices in
                    indices.forEach { self.resource.rooms.remove(at: $0) }
                }
            }
        }
    }
}

struct CreateRoomModal: View {

    @Binding var isPresented: Bool
    @Binding var recipient: String

    var body: some View {
        VStack {
            TitleLabel("Create a New Room")
            UserImage(name: "door")
            TextFieldContent(key: "Recipient", value: self.$recipient)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(.bottom, 20)
            HStack {
                Button(action: {
                    self.isPresented = false
                }){
                    ButtonContent("Ok")
                }.padding(.trailing, 25)

                Button(action: {
                    self.isPresented = false
                    self.recipient = ""
                }){
                    ButtonContent("Cancel")
                }
            }
            Spacer()
        }
    }
}

struct MasterView_Previews: PreviewProvider {
    static var previews: some View {
        MasterView()
    }
}
