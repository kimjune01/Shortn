//
//  UUID+.swift
//  Shorten
//
//  Created by June Kim on 11/3/21.
//

import Foundation

extension UUID {
  func shortened() -> String {
    return uuidString.split(separator: "-").last?.lowercased() ?? "UUID"
  }
}
