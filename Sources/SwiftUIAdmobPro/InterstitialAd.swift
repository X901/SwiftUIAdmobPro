////
//InterstitialAd.swift
//SwiftUIAdMobPro
//
//Created by Basel Baragabah on 18/12/2024.
//Copyright © 2024 Basel Baragabah. All rights reserved.
//

import SwiftUI
import GoogleMobileAds

// MARK: - Interstitial Ad Manager
@MainActor
public class InterstitialAdManager: NSObject, GADFullScreenContentDelegate, ObservableObject {
    private var interstitial: GADInterstitialAd?
    private let adUnitID: String

    @Published public var isAdReady = false
    @Published public var isLoading = false
    
    // Callbacks
    public var onAdLoaded: (() -> Void)?
    public var onAdFailedToLoad: ((Error) -> Void)?
    public var onAdPresented: (() -> Void)?
    public var onAdFailedToPresent: ((Error) -> Void)?
    public var onAdDismissed: (() -> Void)?
    
    // MARK: - Initialize with Ad Unit ID
    public init(adUnitID: String) {
        self.adUnitID = adUnitID
        super.init()
        loadAd()
    }
    
    // MARK: - Load Ad
    public func loadAd() {
        guard !isLoading else { return } // Prevent duplicate loading
        isLoading = true
        
        GADInterstitialAd.load(withAdUnitID: adUnitID, request: ConsentManager.shared.createAdRequest()) { [weak self] ad, error in
            
            // Ensure state updates occur on the Main Actor
            Task { @MainActor in
                guard let self = self else { return } // Handle weak reference safely
                
                self.isLoading = false // Reset loading flag
                
                if let error = error {
                    self.isAdReady = false
                    self.onAdFailedToLoad?(error) // Trigger callback
                    print("Failed to load interstitial ad: \(error.localizedDescription)")
                    return
                }
                
                // Ad successfully loaded
                self.interstitial = ad
                self.interstitial?.fullScreenContentDelegate = self // Assign delegate
                self.isAdReady = true
                self.onAdLoaded?() // Trigger callback
                print("Interstitial ad loaded successfully!")
            }
        }
    }

    
    // MARK: - Show Ad
    public func showAd() {
        guard let rootViewController = UIWindowScene.keyWindow?.rootViewController else {
            print("No root view controller found to present ads.")
            return
        }
        if isAdReady, let ad = interstitial {
            ad.present(fromRootViewController: rootViewController)
        } else {
            print("Ad not ready, reloading...")
            loadAd()
        }
    }
    
    // MARK: - GADFullScreenContentDelegate
    nonisolated public func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Task { @MainActor in
            self.isAdReady = false
            self.onAdPresented?()
        }
    }
    
    nonisolated public func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            self.isAdReady = false
            self.onAdFailedToPresent?(error)
            self.loadAd()
        }
    }
    
    nonisolated public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Task { @MainActor in
            self.isAdReady = false
            self.onAdDismissed?()
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            self.loadAd()
        }
    }
}

// MARK: - Environment Key
public struct InterstitialAdManagerKey: EnvironmentKey {
    public static let defaultValue: InterstitialAdManager? = nil
}

public extension EnvironmentValues {
    var interstitialAdManager: InterstitialAdManager? {
        get { self[InterstitialAdManagerKey.self] }
        set { self[InterstitialAdManagerKey.self] = newValue }
    }
}

// MARK: - Interstitial Ad Modifier
public struct InterstitialAdViewModifier: ViewModifier {
    @StateObject private var adController: InterstitialAdManager
    
    public init(adUnitID: String) {
        _adController = StateObject(wrappedValue: InterstitialAdManager(adUnitID: adUnitID))
    }
    
    public func body(content: Content) -> some View {
        content
            .environment(\.interstitialAdManager, adController)
    }
}

public extension View {
    func interstitialAd(adUnitID: String) -> some View {
        modifier(InterstitialAdViewModifier(adUnitID: adUnitID))
    }
}

// MARK: - UIWindowScene Extension
public extension UIWindowScene {
    static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .windows
            .first(where: \.isKeyWindow)
    }
}

// MARK: - Callback Modifiers
public struct InterstitialAdLoadedModifier: ViewModifier {
    let action: () -> Void
    @Environment(\.interstitialAdManager) var adController
    
    public func body(content: Content) -> some View {
        content
            .onAppear {
                adController?.onAdLoaded = action
            }
    }
}

public struct InterstitialAdFailedToLoadModifier: ViewModifier {
    let action: (Error) -> Void
    @Environment(\.interstitialAdManager) var adController
    
    public func body(content: Content) -> some View {
        content
            .onAppear {
                adController?.onAdFailedToLoad = action
            }
    }
}

public struct InterstitialAdPresentedModifier: ViewModifier {
    let action: () -> Void
    @Environment(\.interstitialAdManager) var adController
    
    public func body(content: Content) -> some View {
        content
            .onAppear {
                adController?.onAdPresented = action
            }
    }
}

public struct InterstitialAdFailedToPresentModifier: ViewModifier {
    let action: (Error) -> Void
    @Environment(\.interstitialAdManager) var adController
    
    public func body(content: Content) -> some View {
        content
            .onAppear {
                adController?.onAdFailedToPresent = action
            }
    }
}

public struct InterstitialAdDismissedModifier: ViewModifier {
    let action: () -> Void
    @Environment(\.interstitialAdManager) var adController
    
    public func body(content: Content) -> some View {
        content
            .onAppear {
                adController?.onAdDismissed = action
            }
    }
}

// MARK: - Extensions for Callback Modifiers
public extension View {
    func onInterstitialAdLoaded(_ action: @escaping () -> Void) -> some View {
        modifier(InterstitialAdLoadedModifier(action: action))
    }
    
    func onInterstitialAdFailedToLoad(_ action: @escaping (Error) -> Void) -> some View {
        modifier(InterstitialAdFailedToLoadModifier(action: action))
    }
    
    func onInterstitialAdPresented(_ action: @escaping () -> Void) -> some View {
        modifier(InterstitialAdPresentedModifier(action: action))
    }
    
    func onInterstitialAdFailedToPresent(_ action: @escaping (Error) -> Void) -> some View {
        modifier(InterstitialAdFailedToPresentModifier(action: action))
    }
    
    func onInterstitialAdDismissed(_ action: @escaping () -> Void) -> some View {
        modifier(InterstitialAdDismissedModifier(action: action))
    }
}
