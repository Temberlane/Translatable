//
//  ContentView.swift
//  Translatable
//
//  Created by Thomas Li on 2025-01-09.
//

import SwiftUI
import AppKit
import Cocoa

struct ContentView: View {
    @State private var clipboardImage: NSImage? = nil
    @State private var clipboardCheckTimer: Timer?
    @State private var lastClipboardData: Data? = nil
    @State private var uniqueImage: Bool = false
    @State private var savedImagePath: String? = nil // New state variable
    @State private var currentPicture: NSImage? = nil // New state variable

    // Define a constant for the History folder path
    private let historyFolderPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("ScreenshotHistory")

    var body: some View {
        GeometryReader { geometry in
            VStack {
                if let image = currentPicture {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    Text("No image in clipboard")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill the available space
                        .background(Color.clear) // Optional, to ensure visibility
                        .multilineTextAlignment(.center) // Optional for multiple lines
                }
                
            }
            .padding()
            .onAppear {
                startClipboardTimer()
                loadMostRecentImage()
            }
            .onDisappear {
                stopClipboardTimer()
            }
            VStack {
                if let path = savedImagePath { // Display the saved image path
                    Text("Saved screenshot to \(path)")
                        .foregroundColor(.blue)
                        .padding()
                        .multilineTextAlignment(.center)
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func loadMostRecentImage() {
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
            }
        } catch {
            print("Failed to load the most recent image: \(error)")
        }
    }

    
    private func startClipboardTimer() {
        clipboardCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            checkClipboardForImage()
        }
    }

    private func stopClipboardTimer() {
        clipboardCheckTimer?.invalidate()
        clipboardCheckTimer = nil
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
            case let data? where data != lastClipboardData:
                lastClipboardData = data
                print("New PNG available")
                saveImageDataToHistoryFolder(data: data, format: "png")
                clipboardImage = NSImage(data: data)
                loadMostRecentImage() // Update currentPicture
            case nil:
                switch pasteboard.data(forType: .tiff) {
                case let data? where data != lastClipboardData:
                    lastClipboardData = data
                    print("New TIFF available")
                    saveImageDataToHistoryFolder(data: data, format: "tiff")
                    clipboardImage = NSImage(data: data)
                    loadMostRecentImage() // Update currentPicture
                default:
                    clipboardImage = nil
                }
            default:
                clipboardImage = nil
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

}
