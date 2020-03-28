import SwiftUI

let storedUsername = "Myusername"
let storedPassword = "Mypassword"

struct LoginView : View {

    @State var username: String = ""
    @State var password: String = ""

    @State var authenticationDidFail: Bool = false
    @State var authenticationDidSucceed: Bool = false
    @EnvironmentObject var viewRouter: ViewRouter

    var body: some View {
        VStack {
            TitleLabel("ClearKeep")
            UserImage(name: "phone")
            TextFieldContent(key: "Username", value: $username)
                .autocapitalization(.none)
                .disableAutocorrection(true)
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
        Backend.shared.register(username, password) { success, error in
            if success {
                self.viewRouter.current = .masterDetail
            } else {
                print("register failed \(String(describing: error))")
            }
        }
    }

    func login() {
        Backend.shared.login(username, password) { success, error in
            if success {
                self.viewRouter.current = .masterDetail
            } else {
                print("login failed \(String(describing: error))")
            }
        }
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
