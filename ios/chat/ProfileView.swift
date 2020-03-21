import SwiftUI

struct ProfileView: View {

    @EnvironmentObject var viewRouter: ViewRouter

    var body: some View {
        Button(action: logout) {
            ButtonContent("LOGOUT")
        }
    }

    func logout() {
        Backend.shared.logout() { success, error in
            if success {
                print("logged out")
            } else {
                print("logout failed \(String(describing: error))")
            }
            self.viewRouter.current = .login
        }
    }
}

struct Profile_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
