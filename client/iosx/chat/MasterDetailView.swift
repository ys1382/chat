// List of Rooms

import SwiftUI

struct MasterDetailView: View {
    @State private var rooms = [String]()
    @State private var recipient: String = ""
    @State private var showMenu = false
    @State private var showModal = false

    var body: some View {

        let drag = DragGesture().onEnded {
            if $0.translation.width < -100 {
                withAnimation {
                    self.showMenu = false
                }
            }
        }

        return NavigationView {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    MasterView(rooms: self.$rooms)
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

struct MasterDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MasterDetailView()
    }
}
