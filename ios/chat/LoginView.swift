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
            WelcomeText()
            UserImage()
            UsernameTextField(username: $username,
                              editingMode: $editingMode)
            PasswordSecureField(password: $password)
            HStack {
                Button(action: { self.viewRouter.currentPage = "page2"}) {
                    LoginButtonContent("LOGIN")
                    .padding(.trailing, 25)
                }
                Button(action: {}) {
                    LoginButtonContent("REGISTER")
                }
            }
        }
        .padding()
    }
}

#if DEBUG
struct LoginView_Previews : PreviewProvider {
    static var previews: some View {
        LoginView().environmentObject(ViewRouter())
    }
}
#endif

struct WelcomeText : View {
    var body: some View {
        return Text("ChitChat")
            .font(.largeTitle)
            .fontWeight(.semibold)
            .padding(.bottom, 20)
    }
}

struct UserImage : View {
    var body: some View {
        return Image("phone")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 150, height: 150)
            .clipped()
            .cornerRadius(150)
            .padding(.bottom, 75)
    }
}

struct Buttons : View {
    let action: () -> Void
//    init() {//action: @escaping () -> Void) {
//        self.action = action
//    }
    var body: some View {
        return HStack {
            Button(action: self.action) {
                LoginButtonContent("LOGIN")
                .padding(.trailing, 25)
            }
            Button(action: {}) {
                LoginButtonContent("REGISTER")
            }
        }
    }
}

struct LoginButtonContent : View {
    init(_ text: String) {
        self.text = text
    }

    private let text: String

    var body: some View {
        return Text(text)
            .font(.headline)
            .foregroundColor(.gray)
            .padding()
            .frame(width: 150, height: 60)
            .cornerRadius(10.0)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1)
        )
    }
}

struct UsernameTextField : View {

    @Binding var username: String
    @Binding var editingMode: Bool

    var body: some View {
        return TextField("Username", text: $username, onEditingChanged: {edit in
                if edit == true {
                    self.editingMode = true
                } else {
                    self.editingMode = false
                }
            })
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
