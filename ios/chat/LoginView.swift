import SwiftUI

let storedUsername = "Myusername"
let storedPassword = "Mypassword"

struct LoginView : View {

    @State var username: String = ""
    @State var password: String = ""

    @State var authenticationDidFail: Bool = false
    @State var authenticationDidSucceed: Bool = false
    @EnvironmentObject var viewRouter: ViewRouter
    @State var editingMode: Bool = false

    var body: some View {
        VStack {
            TitleLabel("ClearKeep")
            UserImage(name: "phone")
            UsernameField(value: $username, editingMode: $editingMode)
            PasswordSecureField(password: $password)
            HStack {
                Button(action: login) {
                    ButtonContent("LOGIN")
                    .padding(.trailing, 25)
                }
                Button(action: register) {
                    ButtonContent("REGISTER")
                }
            }
        }
        .padding()
    }

    func register() {
        Backend.shared.registerWithServer(username, password) { success, error in
            if success {
                self.viewRouter.current = ViewRouter.Page.masterDetail
            } else {
                print("register failed \(String(describing: error))")
            }
        }
    }

    func login() {
        Backend.shared.loginWithServer(username, password) { success, error in
            if success {
                self.viewRouter.current = ViewRouter.Page.masterDetail
            } else {
                print("login failed \(String(describing: error))")
            }
        }
    }
}

struct UsernameField : View {

    @Binding var value: String
    @Binding var editingMode: Bool

    var body: some View {
        return TextField("Username", text: $value, onEditingChanged: { edit in
                self.editingMode = edit
            })
            .autocapitalization(.none)
            .padding()
            .textFieldStyle(RoundedBorderTextFieldStyle())
    }
}

struct PasswordSecureField : View {

    @Binding var password: String

    var body: some View {
        return SecureField("Password", text: $password)
            .padding()
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.bottom, 50)
    }
}

#if DEBUG
struct LoginView_Previews : PreviewProvider {
    static var previews: some View {
        LoginView().environmentObject(ViewRouter())
    }
}
#endif
