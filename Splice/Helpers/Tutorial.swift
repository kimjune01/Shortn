//
//  Tutorial.swift
//  Shortn
//
//  Created by June Kim on 11/10/21.
//

import Foundation

class Tutorial {
  static let shared = Tutorial()

  private let doubleTapTutorialDoneKey = "kim.june.doubleTapTutorialDoneKey"
  private let tapAndHoldContinueDoneKey = "kim.june.tapAndHoldContinueDoneKey"
  private let tapAndHoldStopDoneKey = "kim.june.tapAndHoldStopDoneKey"
  private let scrubTimelineDoneKey = "kim.june.scrubTimelineDoneKey"
  private let deleteSegmentDoneKey = "kim.june.deleteSegmentDoneKey"
  private let previewButtonTapDoneKey = "kim.june.previewButtonTapDoneKey"

  private func allKeys() -> [String] {
    return [
      doubleTapTutorialDoneKey,
      tapAndHoldContinueDoneKey,
      tapAndHoldStopDoneKey,
      scrubTimelineDoneKey,
      deleteSegmentDoneKey,
      previewButtonTapDoneKey
    ]
  }
  
  func nuke() {
    for key in allKeys() {
      UserDefaults.standard.setValue(false, forKey: key)
    }
  }
  
  var doubleTapTutorialDone: Bool {
    get { return UserDefaults.standard.bool(forKey: doubleTapTutorialDoneKey) }
    set { UserDefaults.standard.set(newValue, forKey: doubleTapTutorialDoneKey) }
  }
  
  var tapAndHoldContinueDone: Bool {
    get { return UserDefaults.standard.bool(forKey: tapAndHoldContinueDoneKey) }
    set { UserDefaults.standard.set(newValue, forKey: tapAndHoldContinueDoneKey) }
  }
  
  var tapAndHoldStopDone: Bool {
    get { return UserDefaults.standard.bool(forKey: tapAndHoldStopDoneKey) }
    set { UserDefaults.standard.set(newValue, forKey: tapAndHoldStopDoneKey) }
  }
  
  var scrubTimelineDone: Bool {
    get { return UserDefaults.standard.bool(forKey: scrubTimelineDoneKey) }
    set { UserDefaults.standard.set(newValue, forKey: scrubTimelineDoneKey) }
  }
  
  var deleteSegmentDone: Bool {
    get { return UserDefaults.standard.bool(forKey: deleteSegmentDoneKey) }
    set { UserDefaults.standard.set(newValue, forKey: deleteSegmentDoneKey) }
  }
  
  var previewButtonTapDone: Bool {
    get { return UserDefaults.standard.bool(forKey: previewButtonTapDoneKey) }
    set { UserDefaults.standard.set(newValue, forKey: previewButtonTapDoneKey) }
  }
}
