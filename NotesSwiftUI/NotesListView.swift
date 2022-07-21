import SwiftUI

struct NotesListView: View {

    @State private var showSignOutActionSheet = false
    @State private var selection: String? = ""
    @State private var query: String = ""
    @StateObject var viewModel = NotesViewModel()
    @EnvironmentObject var session: Session

    var body: some View {
        NavigationView {
            List {
                if viewModel.getPinnedNotes() != [] && query.isEmpty {
                    PinnedNotesView()
                }
                if viewModel.getNotPinnedNotes() != [] {
                    AllNotesView()
                }
            }
            .onAppear {
                viewModel.checkNotes()
            }
            .searchable(text: $query, prompt: "Search in all notes")
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Sign Out") {
                        self.showSignOutActionSheet.toggle()
                    } .actionSheet(isPresented: $showSignOutActionSheet) {
                        ActionSheet(title: Text("ARE YOU SURE?"), buttons: [
                            .destructive(Text("Sign Out"), action: {
                                self.session.signOut()
                            }),
                            .cancel()
                        ])
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let id = viewModel.addNote()
                        self.selection = id
                    }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        }
    }

    @ViewBuilder
    func PinnedNotesView() -> some View {
        Section("Pinned") {
            ForEach(viewModel.getPinnedNotes()) { note in
                NavigationLink(destination: NoteView(note: note).environmentObject(viewModel),
                               tag: note.id, selection: $selection) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(note.title)
                            .bold()
                            .lineLimit(1)
                        Text(note.text)
                            .lineLimit(1)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive, action: {
                        viewModel.deleteNote(id: note.id)
                    }) {
                        Image(systemName: "trash")
                    } .tint(.red)
                }
                .swipeActions(edge: .leading) {
                    Button(role: .destructive, action: {
                        note.pinned ? viewModel.unpinNote(id: note.id) : viewModel.pinNote(id: note.id)
                    }) {
                        Image(systemName: note.pinned ? "pin.slash" : "pin")
                    } .tint(.yellow)
                }
            }
        } .headerProminence(.increased)
    }

    @ViewBuilder
    func AllNotesView() -> some View {
        Section("Notes") {
            ForEach(query.isEmpty ? viewModel.getNotPinnedNotes() : viewModel.getSortedNotes(query: query)) { note in
                NavigationLink(destination: NoteView(note: note).environmentObject(viewModel),
                               tag: note.id, selection: $selection) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(note.title)
                            .bold()
                            .lineLimit(1)
                        Text(note.text)
                            .lineLimit(1)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive, action: {
                        viewModel.deleteNote(id: note.id)
                    }) {
                        Image(systemName: "trash")
                    } .tint(.red)
                }
                .swipeActions(edge: .leading) {
                    Button(role: .destructive, action: {
                        note.pinned ? viewModel.unpinNote(id: note.id) : viewModel.pinNote(id: note.id)
                    }) {
                        Image(systemName: note.pinned ? "pin.slash" : "pin")
                    } .tint(.yellow)
                }
            }
        } .headerProminence(.increased)
    }
}
