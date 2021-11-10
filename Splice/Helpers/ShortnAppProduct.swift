//
//  ShortnAppProduct.swift
//  Shortn
//
//  Created by June Kim on 11/9/21.
//

import Foundation
import StoreKit

// Helps with:
// - deciding to show offer
// - deciding to show generosity reminder
// - bridging to IAP helper
// - keeping track of usage
// - querying purchased state
// - gating features

public struct ShortnAppProduct {
  public static let monthlySubscriptionFullAccess = "kim.june.monthlySubscription"
  private static let productIdentifiers: Set<ProductIdentifier> = [monthlySubscriptionFullAccess]
  public static let store = IAPHelper(productIds: ShortnAppProduct.productIdentifiers)

  // primary feature to gate.
  public static var PHPickerSelectionLimit = 1
  //
  static func updatePHPickerSelectionLimit() {
    if store.isProductPurchased(monthlySubscriptionFullAccess) {
      PHPickerSelectionLimit = 0
    }
    
  }
  
  // increment usage counter
  static func incrementUsageCounter() {
//    KeychainWrapper.standard.set("Some String", forKey: "myKey")
  }
}
