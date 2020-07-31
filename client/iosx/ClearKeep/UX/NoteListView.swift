import SwiftUI
import Combine

extension Notification {
    var keyboardHeight: CGFloat {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
    }
}

extension Publishers {
    // 1.
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        // 2.
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
            .map { $0.keyboardHeight }

        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }

        // 3.
        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

private let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .medium
    return dateFormatter
}()

struct Chat_Note: Identifiable {
  let id: UUID
  var title: String
  var content: String
}

final class NoteStore: ObservableObject {
    @Published var notes: [Chat_Note] = [
        .init(id: .init(), title: "note 1234 title", content: "note 1234 content"),
        .init(id: .init(), title: "note 1235 title", content: "note 1235 content"),
        .init(id: .init(), title: "note 1236 title", content: "note 1236 content")
    ]
}



struct NoteListView: View {
    @ObservedObject var store: NoteStore

    var body: some View {
        NavigationView {
                    List {
                        ForEach(store.notes.indices, id: \.self) { index in
                            NavigationLink(destination: EditingView(note: self.$store.notes[index])) {
                                VStack(alignment: .leading) {
                                    Text(titlePreview(title: self.store.notes[index].content))
                                        .font(.headline)
                                    Text(contentPreview(content: self.store.notes[index].content))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .navigationBarTitle(Text("Persons"))
        }
    }
}

class Notes: ObservableObject {
    @Published var items = [Chat_Note]()
}

struct EditingView: View {
    @Environment(\.presentationMode) var presentation
    @Binding var note: Chat_Note

    @State private var keyboardHeight: CGFloat = 0

    
    var body: some View {
        ScrollView {
            Section() {
                TextEditor(/*"content goes here",*/ text: $note.content)
                    .scaledToFill()
//                    .font(.body)
//                    .padding()
//                    .padding(.top, 20)
                        
            }

//            Section {
//                Button("Save") {
//                    self.presentation.wrappedValue.dismiss()
//                }
//            }
        }
            .navigationBarTitle(Text(titlePreview(title: note.content)))
            .padding()
            .padding(.bottom, keyboardHeight)
            .onReceive(Publishers.keyboardHeight) { self.keyboardHeight = $0 }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NoteListView(store: NoteStore())
    }
}

func titlePreview(title: String) -> String {
    if (title == "") {
        return ""
    }
    var preview = String(title.split(separator: "\n").filter{ $0 != "" }[0])
    if (preview.count > 30) {
        let upperBound = preview.index(preview.startIndex, offsetBy: 26)
        preview = String(preview[preview.startIndex..<upperBound]) + "..."
    }
    return preview
}

func contentPreview(content: String) -> String {
    if (content == "") {
        return ""
    }
    var preview = String(content.split(separator: "\n").filter{ $0 != "" }[1])
    if (preview.count > 30) {
        let upperBound = preview.index(preview.startIndex, offsetBy: 26)
        preview = String(preview[preview.startIndex..<upperBound]) + "..."
    }
    return preview
}



