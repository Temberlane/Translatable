//
//  ContentView.swift
//  Translatable
//
//  Created by Thomas Li on 2025-01-09.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var clipboardImage: NSImage? = nil
    @State private var clipboardCheckTimer: Timer?
    @State private var lastClipboardData: Data? = nil

    var body: some View {
        VStack {
            if let image = clipboardImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 300)
            } else {
                Text("No image in clipboard")
                    .foregroundColor(.gray)
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

    private func startClipboardTimer() {
        clipboardCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
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
        }
        
        // Fallback to TIFF data if PNG is not available
        if let data = pasteboard.data(forType: .tiff) {
            return NSImage(data: data)
        }
        
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
}
