import SwiftUI

struct NoteView: View {

    @State var note: Note
    @FocusState var isFocused: Bool
    @EnvironmentObject var viewModel: NotesViewModel

    var body: some View {
        TextView(text: $note.text, id: note.id)
            .environmentObject(viewModel)
            .focused($isFocused)
            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            .onChange(of: note.text) { _ in
                viewModel.updateTextNote(id: note.id, text: note.text)
            }
            .onAppear {
                self.isFocused = true
            }
            .navigationBarTitle(note.title, displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    TextField("Note", text: $note.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .onChange(of: note.title) { _ in
                            viewModel.updateTitleNote(id: note.id, title: note.title)
                        }
                        .multilineTextAlignment(.center)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.isFocused = false
                    }) {
                        Text("Done")
                            .bold()
                    }
                }
            }
    }
}
