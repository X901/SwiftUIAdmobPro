////
//AdMobManager.swift
//SwiftUIAdmobPro
//
//Created by Basel Baragabah on 20/12/2024.
//Copyright © 2024 Basel Baragabah. All rights reserved.
//


import GoogleMobileAds
import Foundation

public class AdMobInitializer {
    @MainActor
    public static func initialize(adPreference: ConsentManager.AdPreference) async throws {
        try await withCheckedThrowingContinuation { continuation in
            GADMobileAds.sharedInstance().start { status in
                print("AdMob SDK initialized with status: \(status.adapterStatusesByClassName)")
                
                Task {
                        await ConsentManager.shared.initialize(adPreference: adPreference)
                        continuation.resume(returning: ())
                }
            }
        }
    }
}
