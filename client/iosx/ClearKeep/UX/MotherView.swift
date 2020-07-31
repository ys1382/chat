// Transitions from login to list screens

import SwiftUI
import Combine

struct MotherView : View {

    @EnvironmentObject var viewRouter: ViewRouter

    var body: some View {
        VStack {
            if viewRouter.current == .login {
                LoginView()
            } else if viewRouter.current == .masterDetail {
                MasterDetailView().transition(.move(edge: .trailing))
            } else if viewRouter.current == .profile {
                ProfileView()
            } else if viewRouter.current == .notes {
                NoteListView(store: NoteStore())
            }
        }
    }
}

struct MotherView_Previews : PreviewProvider {
    static var previews: some View {
        MotherView().environmentObject(ViewRouter())
    }
}

class ViewRouter: ObservableObject {

    enum Page {
        case login
        case masterDetail
        case profile
        case notes
    }

    private static func initialPage() -> Page {
        return Backend.shared.authenticator.loggedIn() ? .masterDetail : .login
    }

    let objectWillChange = PassthroughSubject<ViewRouter,Never>()
    var current: Page = ViewRouter.initialPage() {
        didSet {
            withAnimation() {
                objectWillChange.send(self)
            }
        }
    }
}
