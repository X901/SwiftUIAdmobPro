////
//ConsentManager.swift
//SwiftUIAdmobPro
//
//Created by Basel Baragabah on 23/12/2024.
//Copyright © 2024 Basel Baragabah. All rights reserved.
//

import SwiftUI
import UserMessagingPlatform
import AppTrackingTransparency
import GoogleMobileAds

@MainActor
public final class ConsentManager: ObservableObject {
    // MARK: - Public Properties
    public static let shared = ConsentManager()
    
    @Published public private(set) var canShowPersonalizedAds = false
    @Published public private(set) var isConsentFlowCompleted = false
    @Published public private(set) var isGDPRApplicable = false
    
    // MARK: - Enums
    public enum AdPreference {
        case personalized
        case nonPersonalized
    }
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    
    /// Initializes and requests user consent depending on the desired ad preference.
    public func initialize(adPreference: AdPreference) async {
        await refreshConsentInformation()
        
        switch adPreference {
        case .personalized:
            // Check GDPR if personalized ads are requested.
            isGDPRApplicable = UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus == .required
            
            if isGDPRApplicable {
                do {
                    try await handleUMPConsent()
                } catch {
                    print("Consent Flow Error: \(error.localizedDescription)")
                }
            } else {
                // Non-GDPR Region: use ATT only.
                print("Non-GDPR Region: Using ATT only.")
                isConsentFlowCompleted = true
                await updateConsentStatus()
            }
            
        case .nonPersonalized:
            // Skip consent flow and set non-personalized ads immediately.
            print("Using non-personalized ads only.")
            canShowPersonalizedAds = false
            isConsentFlowCompleted = true
        }
    }
    
    /// Creates a GADRequest that respects the user's tracking and consent settings.
        public func createAdRequest() -> GADRequest {
            let request = GADRequest()
            if !canShowPersonalizedAds {
                let extras = GADExtras()
                extras.additionalParameters = ["npa": "1"]
                request.register(extras)
            }
            return request
        }
    
    
    /// Refreshes the UMP consent information from the server.
      private func refreshConsentInformation() async {
          let parameters = UMPRequestParameters()
          parameters.tagForUnderAgeOfConsent = false
          
          do {
              try await withCheckedThrowingContinuation { continuation in
                  UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { error in
                      if let error = error {
                          // If you need to handle this error differently, do so here.
                          print("Error refreshing consent info: \(error.localizedDescription)")
                      }
                      // Resume regardless—either success or error was logged.
                      continuation.resume(returning: ())
                  }
              }
          } catch {
              print("Consent refresh failed: \(error.localizedDescription)")
          }
      }

    /// Handles the UMP consent flow if it is not yet completed.
       private func handleUMPConsent() async throws {
           guard !isConsentFlowCompleted else { return }
           
           let status = UMPConsentInformation.sharedInstance.consentStatus
           if status == .required {
               try await loadUMPConsentForm()
           }
           
           isConsentFlowCompleted = true
           await updateConsentStatus()
       }


    private func loadUMPConsentForm() async throws {
        let form = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<UMPConsentForm, Error>) in
            UMPConsentForm.load { form, error in
                Task { @MainActor in
                    
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let form = form {
                        continuation.resume(returning: form)
                    } else {
                        let unknownError = NSError(
                          domain: "com.yourapp.consent",
                          code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to load consent form."]
                        )
                        continuation.resume(throwing: unknownError)
                    }
                }
            }
        }
        
        try await presentUMPConsentForm(form)
    }

    /// Presents the UMP consent form to the user.
     private func presentUMPConsentForm(_ form: UMPConsentForm) async throws {
         try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
             guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
                 let error = NSError(
                     domain: "ConsentManagerError",
                     code: 1,
                     userInfo: [NSLocalizedDescriptionKey: "No root view controller to present from."]
                 )
                 continuation.resume(throwing: error)
                 return
             }
             
             form.present(from: rootViewController) { error in
                 if let error = error {
                     continuation.resume(throwing: error)
                 } else {
                     continuation.resume(returning: ())
                 }
             }
         }
     }

    /// Updates the consent status based on GDPR and ATT statuses.
      private func updateConsentStatus() async {
          // Request ATT authorization (iOS 14+).
          let trackingStatus = await ATTrackingManager.requestTrackingAuthorization()
          let attStatusDescription = getATTDescription(trackingStatus)
          
          // Update published properties on the MainActor
          await MainActor.run {
              if isGDPRApplicable {
                  let consentStatus = UMPConsentInformation.sharedInstance.consentStatus
                  let consentDescription = (consentStatus == .obtained) ? "Consent Obtained" : "Consent Not Obtained"
                  
                  // Personalized ads require both GDPR consent & ATT authorization.
                  canShowPersonalizedAds = (consentStatus == .obtained) && (trackingStatus == .authorized)
                  
                  print(
                      """
                      GDPR: Applicable,
                      Consent Status: \(consentDescription),
                      ATT: \(attStatusDescription),
                      Personalized Ads: \(canShowPersonalizedAds)
                      """
                  )
              } else {
                  // If GDPR is not applicable, rely solely on ATT.
                  canShowPersonalizedAds = (trackingStatus == .authorized)
                  print(
                      """
                      GDPR: Not Applicable,
                      ATT: \(attStatusDescription),
                      Personalized Ads: \(canShowPersonalizedAds)
                      """
                  )
              }
          }
      }

    /// Converts ATT AuthorizationStatus to a human-readable string.
       private func getATTDescription(_ status: ATTrackingManager.AuthorizationStatus) -> String {
           switch status {
           case .notDetermined: return "Not Determined"
           case .restricted:    return "Restricted"
           case .denied:        return "Denied"
           case .authorized:    return "Authorized"
           @unknown default:    return "Unknown"
           }
       }

}
