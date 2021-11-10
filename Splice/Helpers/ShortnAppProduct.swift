//
//  ShortnAppProduct.swift
//  Shortn
//
//  Created by June Kim on 11/9/21.
//

import Foundation
import StoreKit
import SwiftKeychainWrapper
import UIKit

// Helps with:
// - deciding to show offer
// v deciding to show generosity reminder
// v bridging to IAP helper
// v keeping track of usage
// v querying purchased state
// - gating features

public struct ShortnAppProduct {
  public static let monthlySubscriptionFullAccess = "kim.june.monthlySubscription"
  private static let productIdentifiers: Set<ProductIdentifier> = [monthlySubscriptionFullAccess]
  public static let store = IAPHelper(productIds: ShortnAppProduct.productIdentifiers)
  
  private static let usageCounterKey = "kim.june.usageCounter"
  private static let maxUsageCountBeforePurchase = 4
  static var usageCount: Int {
    return KeychainWrapper.standard.integer(forKey: usageCounterKey) ?? 0
  }
  static var usageRemaining: Int {
    return maxUsageCountBeforePurchase - usageCount
  }
  // primary feature to gate.
  public static var PHPickerSelectionLimit = 1
  //
  static func updatePHPickerSelectionLimit() {
    if store.isProductPurchased(monthlySubscriptionFullAccess) {
      PHPickerSelectionLimit = 0
    }
    if usageCount <= maxUsageCountBeforePurchase {
      PHPickerSelectionLimit = 0
    }
  }
  
  static func incrementUsageCounter() {
    KeychainWrapper.standard.set(usageCount + 1, forKey: usageCounterKey)
  }
  
  static func resetUsageCounter() {
    KeychainWrapper.standard.set(0, forKey: usageCounterKey)
  }
  
  static func hasFullFeatureAccess() -> Bool {
    return store.isProductPurchased(monthlySubscriptionFullAccess)
  }
  
  static func hasReachedFreeUsageLimit() -> Bool {
    return usageCount > maxUsageCountBeforePurchase
  }
  
  static func shouldShowFreeForNowReminder() -> Bool {
    return !hasFullFeatureAccess() && !hasReachedFreeUsageLimit()
  }
  
  static func shouldShowPurchaseOffer() -> Bool {
    return !hasFullFeatureAccess() && hasReachedFreeUsageLimit()
  }
    
}
