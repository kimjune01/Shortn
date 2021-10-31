//
//  MediaAsset.swift
//   Sequence
//
//  Created by June Kim on 9/5/21.
//

import Foundation

// An abstract class to represent persistent media
protocol MediaAsset: Codable, Hashable, Identifiable {
  var id: UUID { get }
  var url: URL { get }
  var duration: Duration? { get }
}
