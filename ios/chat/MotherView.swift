import SwiftUI
import Combine

struct MotherView : View {
    
    @EnvironmentObject var viewRouter: ViewRouter
    
    var body: some View {
        VStack {
            if viewRouter.currentPage == "page1" {
                LoginView()
            } else if viewRouter.currentPage == "page2" {
                MasterDetailView().transition(.move(edge: .trailing))
            }
        }
    }
}

#if DEBUG
struct MotherView_Previews : PreviewProvider {
    static var previews: some View {
        MotherView().environmentObject(ViewRouter())
    }
}
#endif

class ViewRouter: ObservableObject {
    let objectWillChange = PassthroughSubject<ViewRouter,Never>()
    var currentPage: String = "page1" {
        didSet {
            withAnimation() {
                objectWillChange.send(self)
            }
        }
    }
}
