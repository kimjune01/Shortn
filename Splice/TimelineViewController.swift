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
  func timelineVCDidDeleteSegment()
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
  
  var segmentsVC: SegmentsViewController!
  var isCurrentlyExpanding = false {
    didSet {
      if isCurrentlyExpanding {
        segmentsVC.stopGlowing()
      }
    }
  }
  
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
    addSegmentsVC()
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
  
  func addSegmentsVC() {
    segmentsVC = SegmentsViewController(composition: composition)
    segmentsVC.delegate = self
    addChild(segmentsVC)
    view.addSubview(segmentsVC.view)
    segmentsVC.view.fillParent()
    segmentsVC.didMove(toParent: self)
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
      segmentsVC.startExpandingSegment(time: delegate.currentTimeForDisplay())
    }
  }
  
  func stopExpandingSegment() {
    isCurrentlyExpanding = false
    segmentsVC.stopExpandingSegment()
  }
  
  func updateSegmentsForSplices() {
    segmentsVC.updateSegmentsForSplices()
  }
  
  func setScrubberPosition(to time: TimeInterval) {
    if scrubber.value != Float(time) {
      segmentsVC.stopGlowing()
      scrubber.value = Float(time)
    }
  }
  
  func appearIncluding() {
    scrubber.isEnabled = false
    scrubber.alpha = 0.6
  }
  
  func appearNeutral() {
    scrubber.isEnabled = true
    scrubber.alpha = 1
  }
  
  func deleteSegment(at index: Int) {
    composition.removeSplice(at: index)
    segmentsVC.updateSegmentsForSplices()
    delegate?.timelineVCDidDeleteSegment()
  }
  
  @objc func displayStep(_ displaylink: CADisplayLink) {
    if isCurrentlyExpanding {
      let actualFramesPerSecond = 1 / (displaylink.targetTimestamp - displaylink.timestamp)
      currentFps = actualFramesPerSecond.rounded()
      segmentsVC.expand(rate: advanceRate)
    }
    delegate?.displayLinkStepped()
  }
  
  @objc func didSlideScrubber(_ slider: UISlider) {
    delegate?.sliderValueDragged(to: Double(slider.value))
  }
  
  @objc func didTouchDownScrubber(_ slider: UISlider) {
    delegate?.timelineVCDidTouchDownScrubber()
    segmentsVC.stopGlowing()
  }
  
  @objc func didTouchDoneScrubber(_ slider: UISlider) {
    delegate?.timelineVCDidTouchDoneScrubber()
  }
}

extension TimelineViewController: SegmentsViewControllerDelegate {
  func segmentsVCDidSwipeUpSegment(at index: Int) {
    deleteSegment(at: index)
  }
  
  func segmentsVCDidSelectSegment(at index: Int) {
    let alertController = UIAlertController(title: "Remove Splice?", message: "Don't worry, you can just add it again. To remove splices faster, swipe up on the segment.", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { _ in
      self.deleteSegment(at: index)
    }))
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
      self.segmentsVC.stopGlowing()
    }))
    present(alertController, animated: true, completion: nil)
  }
}
