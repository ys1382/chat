import SwiftUI

struct ProfileView: View {

    @EnvironmentObject var viewRouter: ViewRouter
    @State private var showActionSheet = false

    var body: some View {
        VStack {
            Button(action: logout) {
                ButtonContent("LOGOUT")
                    .padding()
            }
            Button(action: delete) {
                ButtonContent("DELETE")
                .padding()
            }
        }.actionSheet(isPresented: $showActionSheet) {
            self.confirmationSheet
        }
    }

    private func logout() {
        Backend.shared.logout() { success, error in
            if success {
                print("logged out")
            } else {
                print("logout failed \(String(describing: error))")
            }
            self.viewRouter.current = .login
        }
    }
    
    private var confirmationSheet: ActionSheet {
        ActionSheet(
            title: Text("Delete Account"),
            message: Text("Are you sure?"),
            buttons: [
                .cancel {},
                .destructive(Text("Delete")) {
                    self.delete()
                }
            ]
        )
    }

    private func confirmDelete() {
        showActionSheet = true
    }

    private func delete() {
        Backend.shared.deregister() { success, error in
            if success {
                print("account deleted")
            } else {
                print("account deletion failed \(String(describing: error))")
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
