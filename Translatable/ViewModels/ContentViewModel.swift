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
import Foundation


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

    func clearScreenshotHistory() {
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(at: historyFolderPath, includingPropertiesForKeys: nil, options: [])
            for file in files {
                try fileManager.removeItem(at: file)
            }
            print("Cleared ScreenshotHistory directory")
        } catch {
            print("Failed to clear ScreenshotHistory directory: \(error)")
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
            
            var boundingBoxes: [CGRect] = []
            var translatedTexts: [String] = []
            for observation in results {
                if let topCandidate = observation.topCandidates(1).first {
                    print("Recognized text: \(topCandidate.string)")
                    boundingBoxes.append(observation.boundingBox)
                    let translatedText = self.translateText(topCandidate.string)
                    translatedTexts.append(translatedText)
                }
            }
            
            // Draw bounding boxes and translated text on the image
            self.drawBoundingBoxesAndText(on: nsImage, boundingBoxes: boundingBoxes, texts: translatedTexts)
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

    func drawBoundingBoxesAndText(on nsImage: NSImage, boundingBoxes: [CGRect], texts: [String]) {
        let imageSize = nsImage.size
        let newImage = NSImage(size: imageSize)
        
        newImage.lockFocus()
        nsImage.draw(at: .zero, from: CGRect(origin: .zero, size: imageSize), operation: .sourceOver, fraction: 1.0)
        
        let context = NSGraphicsContext.current?.cgContext
        context?.setStrokeColor(NSColor.green.cgColor)
        context?.setLineWidth(2.0)
        
        for (index, box) in boundingBoxes.enumerated() {
            let rect = CGRect(x: box.origin.x * imageSize.width,
                              y: (1 - box.origin.y - box.height) * imageSize.height,
                              width: box.width * imageSize.width,
                              height: box.height * imageSize.height)
            context?.stroke(rect)
            
            // Draw translated text
            let text = texts[index]
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.green
            ]
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            attributedString.draw(in: rect)
        }
        
        newImage.unlockFocus()
        
        // Update the currentPicture with the new image
        DispatchQueue.main.async {
            self.currentPicture = newImage
        }
    }

    func translateText(_ text: String) -> String {
        let apiKey = "YOUR_DEEPL_API_KEY"
        let url = URL(string: "https://api-free.deepl.com/v2/translate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "auth_key=\(apiKey)&text=\(text)&target_lang=EN"
        request.httpBody = body.data(using: .utf8)
        
        var translatedText = "Translation failed"
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            
            if let error = error {
                print("Error making request: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let translations = json["translations"] as? [[String: Any]],
                   let translation = translations.first,
                   let translatedTextResult = translation["text"] as? String {
                    translatedText = translatedTextResult
                } else {
                    print("Invalid response format")
                }
            } catch {
                print("Error parsing response: \(error)")
            }
        }
        
        task.resume()
        semaphore.wait()
        
        return translatedText
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
