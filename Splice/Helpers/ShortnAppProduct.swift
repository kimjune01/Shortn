//
//  ShortnAppProduct.swift
//  Shortn
//
//  Created by June Kim on 11/9/21.
//

import Foundation


public struct ShortnAppProduct {
  
  public static let monthlySubscriptionFullAccess = "kim.june.monthlySubscription"
  
  private static let productIdentifiers: Set<ProductIdentifier> = [monthlySubscriptionFullAccess]
  
  public static let store = IAPHelper(productIds: ShortnAppProduct.productIdentifiers)
}
