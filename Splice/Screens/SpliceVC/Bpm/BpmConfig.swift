//
//  BpmConfig.swift
//  Shorten
//
//  Created by June Kim on 11/2/21.
//

import Foundation

struct BpmConfig {
  var bpm: Int
  var measure: Int
  var isEnabled: Bool
  
  private static let enabledKey = "BpmConfig.isEnabled"
  private static let bpmKey = "BpmConfig.bpm"
  private static let measureKey = "BpmConfig.measure"
  
  static func userDefault() -> BpmConfig {
    let enable = UserDefaults.standard.bool(forKey: BpmConfig.enabledKey)
    var bpm = 108
    let standardBpm = UserDefaults.standard.integer(forKey: bpmKey)
    if standardBpm > 0 {
      bpm = standardBpm
    }
    var measure = 4
    let standardMeasure = UserDefaults.standard.integer(forKey: measureKey)
    if standardMeasure > 0 {
      measure = standardMeasure
    }
    return BpmConfig(bpm: bpm, measure: measure, isEnabled: enable)
  }
  
  func setAsDefault() {
    UserDefaults.standard.setValue(isEnabled, forKey: BpmConfig.enabledKey)
    UserDefaults.standard.setValue(bpm, forKey: BpmConfig.bpmKey)
    UserDefaults.standard.setValue(measure, forKey: BpmConfig.measureKey)
  }
  
  static var bpmOptions: [Int] {
    let min =  50
    let max = 300
    return Array(stride(from: min, to: max, by: 2))
  }
  
  static var measureOptions: [Int] {
    return [2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
  }
}
