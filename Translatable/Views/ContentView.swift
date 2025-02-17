//
//  ContentView.swift
//  Translatable
//
//  Created by Thomas Li on 2025-01-09.
//

import SwiftUI
import AppKit
import Cocoa

// Import the ContentViewModel

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        GeometryReader { geometry in
            VStack {
                if let image = viewModel.currentPicture {
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
                viewModel.startClipboardTimer()
                viewModel.loadMostRecentImage()
            }
            .onDisappear {
                viewModel.stopClipboardTimer()
            }
            VStack {
                if let path = viewModel.savedImagePath { // Display the saved image path
                    Text("Saved screenshot to \(path)")
                        .foregroundColor(.blue)
                        .padding()
                        .multilineTextAlignment(.center)
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}
