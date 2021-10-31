//
//  TimelineViewController.swift
//  Splice
//
//  Created by June Kim on 10/29/21.
//

import Foundation
import UIKit
import Combine

protocol TimelineViewControllerDelegate: AnyObject {
  func currentTimeForDisplay() -> TimeInterval
  func displayLinkStepped()
  func sliderValueDragged(to time: TimeInterval)
  func timelineVCDidTouchDownScrubber()
  func timelineVCDidTouchDoneScrubber()
}

class TimelineViewController: UIViewController {
  weak var delegate: TimelineViewControllerDelegate?
  unowned var composition: SpliceComposition
  static let defaultHeight: CGFloat = 40
  var currentFps: CGFloat = 60
  var advanceRate: CGFloat {
    return view.width / composition.totalDuration / CGFloat(UIScreen.main.maximumFramesPerSecond)
  }
  
  var displayLink: CADisplayLink!
  
  let segmentsContainer = UIView()
  let expandingSegment = UIView()
  private let segmentsTag = 1337
  private let segmentHeight: CGFloat = CustomSlider.defaultHeight
  private var expandingSegmentMinX: CGFloat = 0
  var segmentOriginY: CGFloat = 0
  var isCurrentlyExpanding = false
  
  let scrubber = CustomSlider()
  var subscriptions = Set<AnyCancellable>()
  
  init(composition: SpliceComposition) {
    self.composition = composition
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    subscribeToDisplayLink()
    addExpandingSegment()
    addScrubber()
    observeTimer()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
  
  func subscribeToDisplayLink() {
    displayLink = CADisplayLink(target: self, selector: #selector(displayStep))
    displayLink.isPaused = false
    isCurrentlyExpanding = false
    displayLink.add(to: .main, forMode: .common)
  }
  
  func addExpandingSegment() {
    view.addSubview(segmentsContainer)
    segmentsContainer.fillParent()
    
    segmentOriginY = (TimelineViewController.defaultHeight - segmentHeight) / 2

    expandingSegment.backgroundColor = .systemRed
    expandingSegment.frame = CGRect(x: 0,
                                    y: segmentOriginY,
                                    width: 0,
                                    height: segmentHeight)
    segmentsContainer.addSubview(expandingSegment)
  }
  
  func addScrubber() {
    view.addSubview(scrubber)
    scrubber.centerYInParent()
    scrubber.fillWidthOfParent()
    scrubber.addTarget(self, action: #selector(didSlideScrubber), for: .valueChanged)
    scrubber.addTarget(self, action: #selector(didTouchDownScrubber), for: .touchDown)
    scrubber.addTarget(self, action: #selector(didTouchDoneScrubber), for: .touchUpInside)
    scrubber.addTarget(self, action: #selector(didTouchDoneScrubber), for: .touchDragExit)
    scrubber.minimumValue = 0
    scrubber.maximumValue = Float(composition.totalDuration)
  }
  
  func observeTimer() {
    composition.timeSubject
      .receive(on: DispatchQueue.main)
      .sink { timeInterval in
        self.setScrubberPosition(to: timeInterval)
      }.store(in: &self.subscriptions)
  }
  
  func startExpandingSegment() {
    isCurrentlyExpanding = true
    if let delegate = delegate {
      expandingSegmentMinX = delegate.currentTimeForDisplay() * view.width / composition.totalDuration
    }
  }
  
  func stopExpandingSegment() {
    isCurrentlyExpanding = false
    expandingSegment.frame = CGRect(x: expandingSegmentMinX, y: segmentOriginY, width: 0, height: segmentHeight)
  }
  
  func updateSegmentsForSplices() {
    for eachSubview in segmentsContainer.subviews {
      if eachSubview.tag == segmentsTag {
        eachSubview.removeFromSuperview()
      }
    }
    let totalDuration = composition.totalDuration
    composition.splices.forEach { splice in
      let minX = splice.lowerBound * view.width / totalDuration
      let maxX = splice.upperBound * view.width / totalDuration
      let segmentView = UIView(frame: CGRect(x: minX.rounded(.down),
                                             y: segmentOriginY,
                                             width: (maxX - minX).rounded(.up),
                                             height: segmentHeight))
      segmentView.tag = segmentsTag
      segmentView.backgroundColor = .systemBlue
      segmentsContainer.addSubview(segmentView)
    }
  }
  
  func setScrubberPosition(to time: TimeInterval) {
    scrubber.value = Float(time)
  }
  
  func appearIncluding() {
    scrubber.isEnabled = false
    scrubber.alpha = 0.6
  }
  
  func appearNeutral() {
    scrubber.isEnabled = true
    scrubber.alpha = 1
  }
  
  @objc func displayStep(_ displaylink: CADisplayLink) {
    if isCurrentlyExpanding {
      let actualFramesPerSecond = 1 / (displaylink.targetTimestamp - displaylink.timestamp)
      currentFps = actualFramesPerSecond.rounded()
      expandingSegment.frame = CGRect(x: expandingSegmentMinX,
                                      y: segmentOriginY,
                                      width: expandingSegment.width + advanceRate,
                                      height: segmentHeight)
    }
    delegate?.displayLinkStepped()
  }
  
  @objc func didSlideScrubber(_ slider: UISlider) {
    delegate?.sliderValueDragged(to: Double(slider.value))
  }
  
  @objc func didTouchDownScrubber(_ slider: UISlider) {
    delegate?.timelineVCDidTouchDownScrubber()
  }
  
  @objc func didTouchDoneScrubber(_ slider: UISlider) {
    delegate?.timelineVCDidTouchDoneScrubber()
  }
}
