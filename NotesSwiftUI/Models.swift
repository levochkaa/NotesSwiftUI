import SwiftUI
import Firebase
import FirebaseFirestoreSwift

struct TextView: UIViewRepresentable {

    @Binding var text: String
    @State var id: String
    @EnvironmentObject var viewModel: NotesViewModel

    let textStorage = NSTextStorage()

    func makeCoordinator() -> Coordinator {
        Coordinator(self, $text, id)
    }

    func makeUIView(context: Context) -> UITextView {
        let attrs = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body),
                     NSAttributedString.Key.foregroundColor: UIColor.white]
        let attrString = NSAttributedString(string: text, attributes: attrs)
        textStorage.append(attrString)
        
        let container = NSTextContainer(size: CGSize())
        container.widthTracksTextView = true
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(container)
        textStorage.addLayoutManager(layoutManager)

        let textView = UITextView(frame: CGRect(), textContainer: container)
        textView.attributedText = NSAttributedString(string: self.text)
        context.coordinator.updateAttributedString()
        textView.delegate = context.coordinator
        textView.textColor = .white
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.updateAttributedString()
//        uiView.attributedText = context.coordinator.updateAttributedString()
    }

    class Coordinator: NSObject, UITextViewDelegate {

        var parent: TextView
        var text: Binding<String>
        var id: String

        var replacements: [String: [NSAttributedString.Key: Any]] = [:]

        init(_ textView: TextView, _ text: Binding<String>, _ id: String) {
            self.parent = textView
            self.text = text
            self.id = id

            super.init()

            let font = UIFont.preferredFont(forTextStyle: .body)
            let body = [NSAttributedString.Key.font: font]
            let strike = [NSAttributedString.Key.strikethroughStyle: 1]
            let underline = [NSAttributedString.Key.underlineStyle: 1]

            let descriptorBold = font.fontDescriptor.withSymbolicTraits(.traitBold)
            let fontBold = UIFont(descriptor: descriptorBold!, size: 0)
            let bold = [NSAttributedString.Key.font: fontBold]

            let descriptorItalic = font.fontDescriptor.withSymbolicTraits(.traitItalic)
            let fontItalic = UIFont(descriptor: descriptorItalic!, size: 0)
            let italic = [NSAttributedString.Key.font: fontItalic]

            replacements = ["(\\w+(\\s\\w+)*)": body,
                            "(#s\\w+(\\s\\w+)*#s)": strike,
                            "(#u\\w+(\\s\\w+)*#u)": underline,
                            "(#b\\w+(\\s\\w+)*#b)": bold,
                            "(#i\\w+(\\s\\w+)*#i)": italic]
        }

        func textViewDidChange(_ textView: UITextView) {
            self.parent.text = textView.attributedText.string
            self.updateAttributedString()
        }

        func updateAttributedString() {
            for (pattern, attributes) in replacements {
                do {
                    let regex = try NSRegularExpression(pattern: pattern)
                    let range = NSRange(parent.text.startIndex..., in: parent.text)
                    regex.enumerateMatches(in: parent.text, range: range) { match, flags, stop in
                        if let matchRange = match?.range(at: 1) {
                            if matchRange.location + matchRange.length < parent.text.count {
                                parent.textStorage.addAttributes(attributes, range: matchRange)
                            }
                        }
                    }
                } catch {
                    print("error")
                }
            }
        }
    }
}

struct User: Codable {
    var uid: String
    var notes: [String] = []
}

struct Note: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var text: String
    var pinned: Bool
    var edited: Date
}

class NotesViewModel: ObservableObject {
    @Published var notes = [Note]()
    private let firestore = Firestore.firestore()
    private let user = Auth.auth().currentUser

    init() {
        self.fetchData()
    }

    func getNotPinnedNotes() -> [Note] {
        return self.notes.filter { !$0.pinned }
    }

    func getPinnedNotes() -> [Note] {
        return self.notes.filter { $0.pinned }
    }

    func getSortedNotes(query: String) -> [Note] {
        if query.isEmpty {
            return []
        } else {
            return self.notes.filter { $0.text.lowercased().contains(query.lowercased()) }
        }
    }

    func checkNotes() {
        for note in self.notes {
            if note.text.isEmpty {
                self.deleteNote(id: note.id)
            }
        }
    }

    func fetchData() {
        self.firestore.collection("notes").whereField("user", isEqualTo: user!.uid).order(by: "edited", descending: true).addSnapshotListener {(snapshot, error) in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            self.notes = snapshot!.documents.map({docSnapshot -> Note in
                let data = docSnapshot.data()
                let id = data["id"] as? String ?? ""
                let title = data["title"] as? String ?? ""
                let text = data["text"] as? String ?? ""
                let pinned = data["pinned"] as? Bool ?? false
                let edited = data["edited"] as? Date ?? Date()
                return Note(id: id, title: title, text: text, pinned: pinned, edited: edited)
            })
        }
    }

    func updateTitleNote(id: String, title: String) {
        self.firestore.collection("notes").whereField("id", isEqualTo: id).getDocuments {(snapshot, _) in
            for doc in snapshot!.documents {
                self.firestore.collection("notes").document(doc.documentID).updateData([
                    "title": title,
                    "edited": Date()
                ])
            }
        }
        self.fetchData()
    }

    func updateTextNote(id: String, text: String) {
        self.firestore.collection("notes").whereField("id", isEqualTo: id).getDocuments {(snapshot, _) in
            for doc in snapshot!.documents {
                self.firestore.collection("notes").document(doc.documentID).updateData([
                    "text": text,
                    "edited": Date()
                ])
            }
        }
        self.fetchData()
    }

    func addNote() -> String {
        let id = UUID().uuidString
        self.firestore.collection("notes").addDocument(data: [
            "id": id,
            "title": "Note",
            "text": "",
            "pinned": false,
            "user": user!.uid,
            "edited": Date()
        ])
        return id
    }

    func deleteNote(id: String) {
        self.firestore.collection("notes").whereField("id", isEqualTo: id).getDocuments {(snapshot, _) in
            for doc in snapshot!.documents {
                self.firestore.collection("notes").document(doc.documentID).delete()
            }
        }
    }

    func pinNote(id: String) {
        self.firestore.collection("notes").whereField("id", isEqualTo: id).getDocuments {(snapshot, _) in
            for doc in snapshot!.documents {
                self.firestore.collection("notes").document(doc.documentID).updateData([
                    "pinned": true
                ])
            }
        }
    }

    func unpinNote(id: String) {
        self.firestore.collection("notes").whereField("id", isEqualTo: id).getDocuments {(snapshot, _) in
            for doc in snapshot!.documents {
                self.firestore.collection("notes").document(doc.documentID).updateData([
                    "pinned": false
                ])
            }
        }
    }
}

class Session: ObservableObject {
    @Published var session: User?
    @Published var isAnon: Bool = true
    private let firestore = Firestore.firestore()
    private let auth = Auth.auth()

    func listen() {
        self.auth.addStateDidChangeListener {(auth, user) in
            if let user = user {
                self.isAnon = false
                self.session = User(uid: user.uid)
            } else {
                self.isAnon = true
                self.session = nil
            }
        }
    }

    func signInWithEmail(email: String, password: String) {
        self.auth.signIn(withEmail: email, password: password)
    }

    func signUpWithEmail(email: String, password: String) {
        self.auth.createUser(withEmail: email, password: password)
    }

    func signOut() {
        do {
            try auth.signOut()
            self.session = nil
            self.isAnon = true
        } catch {
            //
        }
    }
}
