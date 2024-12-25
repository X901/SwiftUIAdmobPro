////
//SwiftUIAdMobProApp.swift
//SwiftUIAdMobPro
//
//Created by Basel Baragabah on 16/12/2024.
//Copyright © 2024 Basel Baragabah. All rights reserved.
//

import SwiftUI
import SwiftUIAdmobPro

@main
struct SwiftUIAdMobProApp: App {
    
    init() {
        Task {
            try await AdMobInitializer.initialize(adPreference: .nonPersonalized)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .interstitialAd(adUnitID: "ca-app-pub-3940256099942544/4411468910")

        }
    }
}
