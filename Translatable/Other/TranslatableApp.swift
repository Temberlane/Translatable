//
//  TranslatableApp.swift
//  Translatable
//
//  Created by Thomas Li on 2025-01-09.
//

import SwiftUI

@main
struct TranslatableApp: App {
    @StateObject private var viewModel = ContentViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .inactive || newPhase == .background {
                viewModel.clearScreenshotHistory()
            }
        }
    }
}