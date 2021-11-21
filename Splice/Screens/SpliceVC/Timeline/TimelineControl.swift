//
//  TimelineControl.swift
//  Shortn
//
//  Created by June Kim on 11/20/21.
//

import UIKit

enum ScrubbingState {
  case scrubbing
  case notScrubbing
}

protocol TimelineControlDelegate: AnyObject {
  func currentTimeForDisplay() -> TimeInterval
  func synchronizePlaybackTime()
  func scrubberScrubbed(to time: TimeInterval)
  func timelineVCWillBeginScrubbing()
  func timelineVCDidFinishScrubbing()
  func timelineVCDidDeleteSegment()
}

protocol TimelineControl: AnyObject {
  var delegate: TimelineControlDelegate? { get set }
  var composition: SpliceComposition { get set }
  var view: UIView! { get set }
  var scrubbingState: ScrubbingState { get }

  func appearIncluding()
  func appearNeutral()
  func renderFreshAssets()
  func startExpandingSegment(startTime: TimeInterval)
  func expandingSegment() -> UIView?
  func firstSegment() -> UIView?
  func stopExpandingSegment()
  func updateSegmentsForSplices()

}
