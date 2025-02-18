//
//  SideBarView.swift
//  Translatable
//
//  Created by Thomas Li on 2025-01-13.
//

import SwiftUI

struct SideBarView: View {
    @StateObject private var viewModel = SideBarViewModel()

    var body: some View {
        VStack {
            TextField("Enter text", text: $viewModel.inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: viewModel.saveText) {
                Text("Save")
            }
            .padding()
        }
        .frame(maxWidth: 300) // Set a maximum width for the sidebar
        .padding()
    }
}

#Preview {
    SideBarView()
}