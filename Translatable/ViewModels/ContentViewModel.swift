//
//  ContentViewModel.swift
//  Translatable
//
//  Created by Thomas Li on 2025-02-17.
//
//
//  ContentViewModel.swift
//  Translatable
//
//  Created by Thomas Li on 2025-02-17.
//

import SwiftUI
import AppKit
import Cocoa
import Vision


class ContentViewModel: ObservableObject {
    @Published var clipboardImage: NSImage? = nil
    @Published var savedImagePath: String? = nil
    @Published var currentPicture: NSImage? = nil

    private var clipboardCheckTimer: Timer?
    private var lastClipboardData: Data? = nil
    private let historyFolderPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Containers/Translatable/ScreenshotHistory")

    func startClipboardTimer() {
        clipboardCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.checkClipboardForImage()
        }
    }

    func stopClipboardTimer() {
        clipboardCheckTimer?.invalidate()
        clipboardCheckTimer = nil
    }

    func loadMostRecentImage() {
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(at: historyFolderPath, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles)
            let sortedFiles = files.sorted {
                if let date1 = try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
                   let date2 = try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate {
                    return date1 > date2
                }
                return false
            }
            
            if let mostRecentFile = sortedFiles.first, let imageData = try? Data(contentsOf: mostRecentFile) {
                currentPicture = NSImage(data: imageData)
                savedImagePath = mostRecentFile.path
                print("Loaded most recent image from \(savedImagePath ?? "unknown path")")
                
                // Run text recognition on the currentPicture
                if let currentPicture = currentPicture {
                    recognizeText(from: currentPicture)
                } else {
                    print("No current picture to recognize text from")
                }
            }
        } catch {
            print("Failed to load the most recent image: \(error)")
        }
    }

    private func getImageFromClipboard() -> NSImage? {
        let pasteboard = NSPasteboard.general
        
        // Check if PNG data is available
        if let data = pasteboard.data(forType: .png) {
            return NSImage(data: data)
        } else if let data = pasteboard.data(forType: .tiff) {
            // Fallback to TIFF data if PNG is not available
            return NSImage(data: data)
        }
        
        return nil
    }

    private func checkClipboardForImage() {
        DispatchQueue.main.async {
            let pasteboard = NSPasteboard.general
            
            // Check for image data
            switch pasteboard.data(forType: .png) {
            case let data? where data != self.lastClipboardData:
                self.lastClipboardData = data
                print("New PNG available")
                self.saveImageDataToHistoryFolder(data: data, format: "png")
                self.clipboardImage = NSImage(data: data)
                self.loadMostRecentImage() // Update currentPicture
            case nil:
                switch pasteboard.data(forType: .tiff) {
                case let data? where data != self.lastClipboardData:
                    self.lastClipboardData = data
                    print("New TIFF available")
                    self.saveImageDataToHistoryFolder(data: data, format: "tiff")
                    self.clipboardImage = NSImage(data: data)
                    self.loadMostRecentImage() // Update currentPicture
                default:
                    self.clipboardImage = nil
                }
            default:
                self.clipboardImage = nil
            }
        }
    }
    
    private func saveImageDataToHistoryFolder(data: Data, format: String) {
        let fileManager = FileManager.default
        
        // Create the Data folder if it doesn't exist
        if (!fileManager.fileExists(atPath: historyFolderPath.path)) {
            do {
                try fileManager.createDirectory(at: historyFolderPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create Data folder: \(error)")
                return
            }
        }
        
        // Create a unique filename
        let timestamp = Date().timeIntervalSince1970
        let filename = "screenshot_\(timestamp).\(format)"
        let fileURL = historyFolderPath.appendingPathComponent(filename)
        
        // Write the data to the file
        do {
            try data.write(to: fileURL)
            savedImagePath = fileURL.path // Set the path to the state variable
            print("Saved screenshot to \(fileURL.path)")
        } catch {
            print("Failed to save screenshot: \(error)")
        }
    }
    

    func recognizeText(from nsImage: NSImage) {
        guard let cgImage = nsImage.cgImage else {
            print("Failed to convert NSImage to CGImage")
            return
        }
        print("Successfully converted NSImage to CGImage")

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Error in text recognition request: \(error)")
                return
            }
            
            guard let results = request.results as? [VNRecognizedTextObservation] else {
                print("No text recognized")
                return
            }
            
            for observation in results {
                if let topCandidate = observation.topCandidates(1).first {
                    print("Recognized text: \(topCandidate.string)")
                }
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
            print("Text recognition performed successfully")
        } catch {
            print("Error performing text recognition: \(error)")
        }
    }
}

// Move the extension outside of the class
extension NSImage {
    var cgImage: CGImage? {
        var rect = CGRect(origin: .zero, size: self.size)
        guard let cgImage = self.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
            print("Failed to get CGImage from NSImage")
            return nil
        }
        print("Successfully got CGImage from NSImage")
        return cgImage
    }
}
