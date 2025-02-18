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
        GeometryReader { geometry in
            VStack {
                TextField("Enter text", text: $viewModel.inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: viewModel.saveText) {
                    Text("Save")
                }
                .padding()
            }
            .frame(width: geometry.size.width * 0.15) // Set width to 15% of available width
            .padding()
        }
    }
}

#Preview {
    SideBarView()
}