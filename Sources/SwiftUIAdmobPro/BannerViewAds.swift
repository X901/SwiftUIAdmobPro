////
//BannerViewAds.swift
//SwiftUIAdMobPro
//
//Created by Basel Baragabah on 16/12/2024.
//Copyright © 2024 Basel Baragabah. All rights reserved.
//

import SwiftUI
import GoogleMobileAds

// MARK: - Banner View Controller & Delegate
public protocol BannerViewControllerWidthDelegate: AnyObject {
    func bannerViewController(_ bannerViewController: BannerViewController, didUpdate width: CGFloat)
}

public class BannerViewController: UIViewController {
    public weak var delegate: BannerViewControllerWidthDelegate?
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.bannerViewController(
            self,
            didUpdate: view.frame.inset(by: view.safeAreaInsets).size.width
        )
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.delegate?.bannerViewController(
            self,
            didUpdate: self.view.frame.inset(by: self.view.safeAreaInsets).size.width
        )
    }
}

public struct BannerView: UIViewControllerRepresentable {
    private let bannerView = GADBannerView()
    
    private let adUnitID: String
    private var backgroundColor: UIColor = .clear
    private var adSize: GADAdSize?

    private var onAdLoaded: (() -> Void)?
    private var onAdFailedToLoad: ((Error) -> Void)?
    private var onAdClicked: (() -> Void)?
    private var onAdClosed: (() -> Void)?

    @State private var viewWidth: CGFloat = .zero

    public init(adUnitID: String) {
        self.adUnitID = adUnitID
    }

    public func makeUIViewController(context: Context) -> BannerViewController {
        let bannerViewController = BannerViewController()

        // Configure banner view
        bannerView.adUnitID = adUnitID
        bannerView.backgroundColor = backgroundColor
        bannerView.rootViewController = bannerViewController
        bannerView.delegate = context.coordinator
        bannerView.translatesAutoresizingMaskIntoConstraints = false

        bannerViewController.view.addSubview(bannerView)

        NSLayoutConstraint.activate([
            bannerView.bottomAnchor.constraint(equalTo: bannerViewController.view.safeAreaLayoutGuide.bottomAnchor),
            bannerView.leftAnchor.constraint(equalTo: bannerViewController.view.leftAnchor),
            bannerView.rightAnchor.constraint(equalTo: bannerViewController.view.rightAnchor),
        ])

        bannerViewController.delegate = context.coordinator
        return bannerViewController
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        if viewWidth != .zero {
            let adSize = adSize ?? GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
            bannerView.adSize = adSize
            if uiViewController.preferredContentSize != adSize.size {
                uiViewController.preferredContentSize = adSize.size
            }
            
        } else {
            bannerView.adSize = GADAdSizeBanner
        }
        
        bannerView.load(ConsentManager.shared.createAdRequest())
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: - Modifiers for Callbacks
    public func onAdLoaded(_ action: @escaping () -> Void) -> BannerView {
        var copy = self
        copy.onAdLoaded = action
        return copy
    }

    public func onAdFailedToLoad(_ action: @escaping (Error) -> Void) -> BannerView {
        var copy = self
        copy.onAdFailedToLoad = action
        return copy
    }

    public func onAdClicked(_ action: @escaping () -> Void) -> BannerView {
        var copy = self
        copy.onAdClicked = action
        return copy
    }

    public func onAdClosed(_ action: @escaping () -> Void) -> BannerView {
        var copy = self
        copy.onAdClosed = action
        return copy
    }
    
    public func backgroundColor(_ color: UIColor) -> BannerView {
        var copy = self
        copy.backgroundColor = color
        return copy
    }

    public func adSize(_ size: GADAdSize) -> BannerView {
        var copy = self
        copy.adSize = size
        return copy
    }

    // MARK: - Coordinator
    public class Coordinator: NSObject, BannerViewControllerWidthDelegate, GADBannerViewDelegate {
        public let parent: BannerView

        public init(parent: BannerView) {
            self.parent = parent
        }

        // MARK: - Width Delegate
        public func bannerViewController(_ bannerViewController: BannerViewController, didUpdate width: CGFloat) {
            Task { @MainActor [parent] in
                parent.viewWidth = width
            }
        }

        // MARK: - Banner View Delegate
        public func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            Task { @MainActor [parent] in
                parent.onAdLoaded?()
            }
        }

        public func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            Task { @MainActor [parent] in
                parent.onAdFailedToLoad?(error)
            }
        }

        public func bannerViewDidRecordClick(_ bannerView: GADBannerView) {
            Task { @MainActor [parent] in
                parent.onAdClicked?()
            }
        }

        public func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
            Task { @MainActor [parent] in
                parent.onAdClosed?()
            }
        }
    }
}
