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
            return NSImage(data: data)
        }
        
        // Fallback to TIFF data if PNG is not available
        if let data = pasteboard.data(forType: .tiff) {
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
}
