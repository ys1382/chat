// List of Rooms

import SwiftUI

struct MasterDetailView: View {
    @State private var rooms = [String]()
    @State private var showModal = false
    @State private var recipient: String = ""

    var body: some View {
        NavigationView {
            MasterView(rooms: $rooms)
                .navigationBarTitle(Text("Rooms"), displayMode: .inline)
                .navigationBarItems(
                    leading: EditButton(),
                    trailing: Button( action: {
                        self.showModal = true
                    }){
                        Image(systemName: "plus")
                    }
                    .sheet(isPresented: $showModal, onDismiss: {
                        if !self.recipient.isEmpty {
                            withAnimation { self.rooms.insert(self.recipient, at: 0) }
                            self.recipient = ""
                        }
                    }) {
                        ModalView(isPresented: self.$showModal, recipient: self.$recipient)
                    }
                )
            DetailView()
        }.navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

struct ModalView: View {

    @Binding var isPresented: Bool
    @Binding var recipient: String

    var body: some View {
        VStack {
            TitleLabel("Create a New Room")
            UserImage(name: "door")
            TextFieldContent(key: "Recipient", value: self.$recipient)
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

struct MasterView: View {
    @Binding var rooms: [String]

    var body: some View {
        List {
            ForEach(rooms, id: \.self) { room in
                NavigationLink(
                    destination: DetailView(selectedRoom: room)
                ) {
                    Text(room)
                }
            }.onDelete { indices in
                indices.forEach { self.rooms.remove(at: $0) }
            }
        }
    }
}

struct DetailView: View {
    var selectedRoom: String?

    var body: some View {
        Group {
            if selectedRoom != nil {
                Text(selectedRoom ?? "Room")
            } else {
                Text("Detail view content goes here")
            }
        }.navigationBarTitle(Text("Detail"))
    }
}

struct MasterDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MasterDetailView()
    }
}
