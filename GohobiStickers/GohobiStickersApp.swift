//
//  GohobiStickersApp.swift
//  GohobiStickers
//
//  Created by NakaokaRei on 2026/08/01.
//

import SwiftUI

@main
struct GohobiStickersApp: App {
    @State private var store = StampStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
