# SwiftUIAdmobPro

`SwiftUIAdmobPro` is a Swift package designed to integrate Google AdMob seamlessly with SwiftUI, making it feel as native as any other SwiftUI view or component. Unlike other libraries, `SwiftUIAdmobPro` provides a clean, SwiftUI-first API that makes managing AdMob banners and interstitial ads simple and efficient.

---


## Features

- Pure SwiftUI support for AdMob integration.
- Declarative modifiers for handling Ad events.
- Adaptive banner sizes and interstitial ads.
- Simple initialization and configuration.
- Easily extensible with callback support.

---

## Installation
### Using Swift Package Manager (SPM)
1. In Xcode, go to **File > Add Packages**.
2. Enter the repository URL: `https://github.com/X901/SwiftUIAdmobPro`.
3. Select the branch `main` to install the library.
4. Add it to your desired targets.

> **Note:** The AdMob SDK is already included in `SwiftUIAdmobPro`. You do not need to add it separately.

---

## Usage

### **1. Configure App Identifier and SKAdNetworkIdentifier in Info.plist**  

To ensure proper ad attribution and privacy compliance, you need to configure your **App Identifier** and **SKAdNetworkIdentifier** in the `Info.plist` file.  

Follow the detailed steps provided in Google's official guide:  
[AdMob iOS Privacy Strategies](https://developers.google.com/ad-manager/mobile-ads-sdk/ios/quick-start#update_your_infoplist)  

> **Important:**  Adding **SKAdNetworkIdentifiers** is **required** for accurate ad attribution and reporting on iOS devices.  


### 2. Initialize AdMob
Initialize AdMob when your app starts:

```swift
import SwiftUIAdmobPro

@main
struct MyApp: App {
    init() {
        AdMobInitializer.initialize()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 3. Display a Banner Ad
Add a banner ad to your SwiftUI view:

```swift
import SwiftUIAdmobPro

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Welcome to SwiftUIAdmobPro")
                .font(.headline)
            
            BannerView(adUnitID: "ca-app-pub-3940256099942544/2435281174")
                .backgroundColor(.black)
                .onAdLoaded {
                    print("Banner Ad Loaded")
                }
                .onAdFailedToLoad { error in
                    print("Failed to load ad: \(error)")
                }
                .onAdClicked {
                    print("Ad Clicked")
                }
                .onAdClosed {
                    print("Ad Closed")
                }
                .frame(height: 50)
        }
    }
}
```
> **Note:** Replace the test ad unit ID with your actual Banner Ad Unit ID.


## Banner Ad | Event Modifiers
- `.onAdLoaded` Triggered when the banner ad successfully loads.
- `.onAdFailedToLoad` Triggered when the banner ad fails to load.
- `.onAdClicked` Triggered when the ad is clicked.
- `.onAdClosed` Triggered when the ad is closed by the user

> **Note:** All event modifiers are optional.


### 4. Show Interstitial Ads

#### Step-by-Step Explanation
To show interstitial ads, the `InterstitialAdManager` must be available in the SwiftUI environment. You achieve this by applying the `.interstitialAd` modifier to a **parent view**. This modifier sets up the `InterstitialAdManager`, which child views can access via the `@Environment`.

#### Example Code
Here's an example of where to apply the `.interstitialAd` modifier and how to access it in child views:

```swift
import SwiftUI
import SwiftUIAdmobPro

@main
struct MyApp: App {
    init() {
        AdMobInitializer.initialize()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                  .interstitialAd(adUnitID: "ca-app-pub-3940256099942544/4411468910")
        }
    }
}
```
> **Note:** Replace test ads with your Interstitial adUnitID


### How to Display Interstitial Ads

To show an interstitial ad from within your SwiftUI view, use the @Environment property wrapper to retrieve the InterstitialAdManager. Then, call the showAd() method on the manager to present the ad.

Here’s an example of how to display interstitial ads:


```swift
struct ContentView: View {
    @Environment(\.interstitialAdManager) var adManager

    var body: some View {
        VStack {
            Text("SwiftUIAdmobPro")
   
            VStack(spacing: 20) {
                
                Button(action: {
                    adManager?.showAd()  
                }) {
                    Text("Tap Me")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }

            }
        .onInterstitialAdLoaded { print("Interstitial loaded") }
        .onInterstitialAdFailedToLoad { error in print("Interstitial failed: \(error)") }
        .onInterstitialAdPresented { print("Interstitial presented") }
        .onInterstitialAdFailedToPresent { error in print("Presentation failed: \(error)") }
        .onInterstitialAdDismissed { print("Interstitial dismissed") }
         
        }

    }
```
> **Note:**  Environment Access: Use @Environment(\.interstitialAdManager) to retrieve the InterstitialAdManager in child views. This allows you to present ads by calling showAd() on the manager.


## Interstitial Ads | Event Modifiers

- `onInterstitialAdLoaded` Triggered when the interstitial ad successfully loads.
- `onInterstitialAdFailedToLoad`: Handles errors when loading the interstitial ad.
- `onInterstitialAdPresented` Triggered when the interstitial ad is displayed.
- `onInterstitialAdFailedToPresent` Handles errors when presenting the interstitial ad.
- `onInterstitialAdDismissed` Triggered when the interstitial ad is dismissed.
> **Note:** All event modifiers are optional.






