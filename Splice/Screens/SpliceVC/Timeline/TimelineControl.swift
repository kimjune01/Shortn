//
//  TimelineControl.swift
//  Shortn
//
//  Created by June Kim on 11/20/21.
//

import UIKit

enum ScrubbingState: Equatable {
  case scrubbing(Int?) // indicate the splice that it's scrubbing along to.
  case notScrubbing
}

protocol TimelineControlDelegate: AnyObject {
  func currentTimeForDisplay() -> TimeInterval
  func synchronizePlaybackTime()
  func scrubberScrubbed(to time: TimeInterval)
  func scrubbingStateChanged(_ scrubbingState: ScrubbingState)
  func timelineVCWillBeginScrubbing()
  func timelineVCDidFinishScrubbing()
  func timelineVCDidDeleteSegment()
}

protocol TimelineControl: AnyObject {
  var delegate: TimelineControlDelegate? { get set }
  var composition: SpliceComposition { get set }
  var view: UIView! { get set }
  var scrubbingState: ScrubbingState { get }
  var currentlySelectedIndex: Int? { get }

  func appearIncluding()
  func appearNeutral()
  func renderFreshAssets()
  func startExpandingSegment(startTime: TimeInterval)
  func expandingInterval() -> UIView?
  func firstInterval() -> UIView?
  func stopExpandingSegment()
  func updateSegmentsForSplices()

}
