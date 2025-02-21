//
//  SideBarViewModel.swift
//  Translatable
//
//  Created by Thomas Li on 2025-01-13.
//

import SwiftUI

class SideBarViewModel: ObservableObject {
    @Published var inputText: String = ""
    private let dataFolderPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Containers/Translatable/Data")

    func saveText() {
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

        let filename = "text_data.json"
        let fileURL = dataFolderPath.appendingPathComponent(filename)

        var jsonData: [String: String] = [:]

        // Read existing data if the file exists
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                if let existingData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                    jsonData = existingData
                }
            } catch {
                print("Failed to read existing data: \(error)")
            }
        }

        // Append new text
        let timestamp = Date().timeIntervalSince1970
        jsonData["text_\(timestamp)"] = inputText

        // Write updated data back to the file
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonData, options: .prettyPrinted)
            try data.write(to: fileURL)
            print("Saved text to \(fileURL.path)")
        } catch {
            print("Failed to save text: \(error)")
        }
    }
}
