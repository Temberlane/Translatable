import SwiftUI

struct SideBarView: View {
    @State private var inputText: String = ""
    private let dataFolderPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Containers/Translatable/Data")

    var body: some View {
        VStack {
            TextField("Enter text", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: saveText) {
                Text("Save")
            }
            .padding()
        }
        .frame(maxWidth: 300)
        .padding()
    }

    private func saveText() {
        let fileManager = FileManager.default

        // Create the Data folder if it doesn't exist
        if !fileManager.fileExists(atPath: dataFolderPath.path) {
            do {
                try fileManager.createDirectory(at: dataFolderPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create Data folder: \(error)")
                return
            }
        }

        // Create a unique filename
        let timestamp = Date().timeIntervalSince1970
        let filename = "text_\(timestamp).json"
        let fileURL = dataFolderPath.appendingPathComponent(filename)

        // Create JSON data
        let jsonData: [String: String] = ["text": inputText]
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonData, options: .prettyPrinted)
            try data.write(to: fileURL)
            print("Saved text to \(fileURL.path)")
        } catch {
            print("Failed to save text: \(error)")
        }
    }
}

#Preview {
    SideBarView()
}