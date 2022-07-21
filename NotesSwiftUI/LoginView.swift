import SwiftUI

struct LoginView: View {

    @State private var email = ""
    @State private var password = ""
    @State private var isLogin = true
    @EnvironmentObject var session: Session

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("E-mail", text: $email)
                    SecureField("Password", text: $password)
                }
                Section {
                    Button(action: {
                        if isLogin {
                            self.session.signInWithEmail(email: email, password: password)
                        } else {
                            self.session.signUpWithEmail(email: email, password: password)
                        }
                    }) {
                        Text(isLogin ? "Login" : "Create account")
                            .animation(.default)
                    }
                }
            }
            .navigationBarTitle("Welcome", displayMode: .inline)
            .safeAreaInset(edge: .top) {
                Picker("", selection: $isLogin) {
                    Text("Login").tag(true)
                    Text("Create account").tag(false)
                } .pickerStyle(.segmented)
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
