import SwiftUI

struct ContentView: View {

    @ObservedObject var session = Session()

    init() {
        session.listen()
    }

    var body: some View {
        if self.session.isAnon {
            LoginView().environmentObject(session)
        } else {
            NotesListView().environmentObject(session)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
