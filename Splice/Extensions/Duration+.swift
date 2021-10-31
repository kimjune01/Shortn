//
//  Duration+.swift
//   Sequence
//
//  Created by June Kim on 9/6/21.
//

import Foundation

typealias Duration = TimeInterval

extension Duration {
  var secondsDescription: String {
    return "\(Int(self)) seconds"
  }
}
