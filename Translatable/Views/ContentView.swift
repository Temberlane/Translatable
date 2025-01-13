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

    var body: some View {
            GeometryReader { geometry in
                VStack {
                    if let image = clipboardImage {
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
                }
                .onDisappear {
                    stopClipboardTimer()
                }
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
            saveImageFromPasteboard()
            return NSImage(data: data)
        }
        
        // Fallback to TIFF data if PNG is not available
        if let data = pasteboard.data(forType: .tiff) {
            saveImageFromPasteboard()
            return NSImage(data: data)
        }
        
        //there is a bug where weird formats make it flash the icon
//        if let data = pasteboard.data(forType: .dng) {
//            return nil
//        }
        
        
        return nil
    }

    private func checkClipboardForImage() {
        DispatchQueue.main.async {
            let pasteboard = NSPasteboard.general
            
            // Check for PNG data
            if let data = pasteboard.data(forType: .png),
               data != lastClipboardData {
                lastClipboardData = data
                clipboardImage = NSImage(data: data)
                return
            }
            
            // Check for TIFF data if PNG is not available
            if let data = pasteboard.data(forType: .tiff),
               data != lastClipboardData {
                lastClipboardData = data
                clipboardImage = NSImage(data: data)
                return
            }
            
            // No image data
            clipboardImage = nil
            lastClipboardData = nil
        }
    }
    

    func saveImageFromPasteboard() {
        // Access the pasteboard
        let pasteboard = NSPasteboard.general
        
        // Get image data from the pasteboard
        if let data = pasteboard.data(forType: .png),
           let image = NSImage(data: data) {
            
            // Specify the directory path
            let fileManager = FileManager.default
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let historyFolder = documentsDirectory.appendingPathComponent("Translatable/History")
            
            // Ensure the folder exists
            if !fileManager.fileExists(atPath: historyFolder.path) {
                do {
                    try fileManager.createDirectory(at: historyFolder, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("Failed to create folder: \(error)")
                    return
                }
            }
            
            // Define the file path
            let fileName = "image-\(UUID().uuidString).png"
            let filePath = historyFolder.appendingPathComponent(fileName)
            
            // Convert NSImage to PNG data
            guard let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: .png, properties: [:]) else {
                print("Failed to convert NSImage to PNG data")
                return
            }
            
            // Write the PNG data to the file
            do {
                try pngData.write(to: filePath)
                print("Image saved to: \(filePath.path)")
            } catch {
                print("Failed to save image: \(error)")
            }
        } else {
            print("No image found on the pasteboard")
        }
    }

}
