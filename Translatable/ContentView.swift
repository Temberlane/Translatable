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
    private var clipboardCheckTimer: Timer?

    var body: some View {
        VStack {
            if let image = clipboardImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Text("No image in clipboard")
            }
        }
        .padding()
        .onAppear {
            // Set up the timer to check the clipboard every 5 seconds
            clipboardCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                checkClipboardForImage()
            }
        }
        .onDisappear {
            // Invalidate the timer when the view disappears
            clipboardCheckTimer?.invalidate()
        }
    }

    private func getImageFromClipboard() -> NSImage? {
        if let data = NSPasteboard.general.pasteboardItems?.first?.data(forType: .tiff) {
            return NSImage(data: data)
        }
        return nil
    }

    private func checkClipboardForImage() {
        DispatchQueue.main.async {
            if let image = getImageFromClipboard() {
                clipboardImage = image
            }
        }
    }
}

@main
struct TranslatableApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
