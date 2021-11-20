//
//  TimelineControl.swift
//  Shortn
//
//  Created by June Kim on 11/20/21.
//

import UIKit

protocol TimelineControlDelegate: AnyObject {
  func currentTimeForDisplay() -> TimeInterval
  func displayLinkStepped()
  func sliderValueDragged(to time: TimeInterval)
  func timelineVCDidTouchDownScrubber()
  func timelineVCDidTouchDoneScrubber()
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
  func startExpandingSegment()
  func expandingSegment() -> UIView?
  func firstSegment() -> UIView?  
  func stopExpandingSegment()
  func updateSegmentsForSplices()

}
