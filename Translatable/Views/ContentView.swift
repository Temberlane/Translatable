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
    @EnvironmentObject var viewModel: ContentViewModel

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                SideBarView() // Add the SideBarView on the left
                    .frame(width: geometry.size.width * 0.15) // Set width to 15% of available width
                
                VStack {
                    if let image = viewModel.currentPicture {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width * 0.85, height: geometry.size.height) // Set width to 85% of available width
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 2)
                            )
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
                // VStack {
                //     if let path = viewModel.savedImagePath { // Display the saved image path
                //         Text("Saved screenshot to \(path)")
                //             .foregroundColor(.blue)
                //             .padding()
                //             .multilineTextAlignment(.center)
                //     }
                // }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }
}

#Preview {
    ContentView()
}
