// List of Rooms

import SwiftUI

struct MasterDetailView: View {
    @State private var rooms = [String]()
    @State private var recipient: String = ""
    @State private var showMenu = false
    @State private var showModal = false

    var body: some View {

        let drag = DragGesture()
        .onEnded {
            if $0.translation.width < -100 {
                withAnimation {
                    self.showMenu = false
                }
            }
        }

        return NavigationView {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    MasterView(rooms: self.$rooms, detail: self.$recipient)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .offset(x: self.showMenu ? geometry.size.width/2 : 0)
                        .disabled(self.showMenu ? true : false)
                    if self.showMenu {
                        MenuView()
                            .frame(width: geometry.size.width/2)
                            .transition(.move(edge: .leading))
                    }
                }
                .gesture(drag)
            }
            .navigationBarTitle("Rooms", displayMode: .inline)
            .navigationBarItems(leading:
                Button(action: {
                    withAnimation {
                        self.showMenu.toggle()
                    }
                }){
                    Image(systemName: "line.horizontal.3").imageScale(.large)
                },
                trailing: Button( action: {
                    self.recipient = ""
                    self.showModal = true
                }){
                    Image(systemName: "plus")
                }
            ).sheet(isPresented: $showModal, onDismiss: {
                if !self.recipient.isEmpty {
                    self.rooms.insert(self.recipient, at: 0)
                }
            }) {
                CreateRoomModal(isPresented: self.$showModal,
                                recipient: self.$recipient)
            }
        }
    }
}

struct MainView: View {
    
    @Binding var showMenu: Bool
    
    var body: some View {
        Button(action: {
            withAnimation {
               self.showMenu = true
            }
        }) {
            Text("Show Menu")
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
    @Binding var detail: String

    var body: some View {
        Group {
            List {
                ForEach(rooms, id: \.self) { room in
                    NavigationLink(
                        destination: DetailView(room: room)
                    ) {
                        Text(room)
                    }
                }.onDelete { indices in
                    indices.forEach { self.rooms.remove(at: $0) }
                }
            }
        }
    }
}

struct MasterDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MasterDetailView()
    }
}
