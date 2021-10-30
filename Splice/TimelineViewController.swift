//
//  TimelineViewController.swift
//  Splice
//
//  Created by June Kim on 10/29/21.
//

import Foundation
import UIKit

protocol TimelineViewControllerDelegate: AnyObject {
  func currentTimeForDisplay() -> TimeInterval
}

class TimelineViewController: UIViewController {
  weak var delegate: TimelineViewControllerDelegate?
  unowned var composition: SpliceComposition
  var currentFps: CGFloat = 60
  var advanceRate: CGFloat {
    return view.width / composition.totalDuration / CGFloat(UIScreen.main.maximumFramesPerSecond)
  }
  
  var displayLink: CADisplayLink!
  
  let expandingSegment = UIView()
  private let segmentsTag = 1337
  private let segmentHeight: CGFloat = 20
  private var expandingSegmentMinX: CGFloat = 0
  
  init(composition: SpliceComposition) {
    self.composition = composition
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemYellow
    subscribeToDisplayLink()
    addExpandingSegment()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
  
  func subscribeToDisplayLink() {
    displayLink = CADisplayLink(target: self, selector: #selector(displayStep))
    displayLink.isPaused = true
    displayLink.add(to: .main, forMode: .common)
  }
  
  func addExpandingSegment() {
    expandingSegment.backgroundColor = .systemTeal
    expandingSegment.frame = CGRect(x: 0, y: 0, width: 0, height: segmentHeight)
    view.addSubview(expandingSegment)
  }
  
  func startExpandingSegment() {
    displayLink.isPaused = false
    if let delegate = delegate {
      expandingSegmentMinX = delegate.currentTimeForDisplay() * view.width / composition.totalDuration
    }
  }
  
  func stopExpandingSegment() {
    displayLink.isPaused = true
    expandingSegment.frame = CGRect(x: expandingSegmentMinX, y: 0, width: 0, height: segmentHeight)
  }
  
  func updateSegmentsForSplices() {
    for eachSubview in view.subviews {
      if eachSubview.tag == segmentsTag {
        eachSubview.removeFromSuperview()
      }
    }
    let totalDuration = composition.totalDuration
    composition.splices.forEach { splice in
      let minX = splice.lowerBound * view.width / totalDuration
      let maxX = splice.upperBound * view.width / totalDuration
      let segmentView = UIView(frame: CGRect(x: minX.rounded(.down),
                                             y: 0,
                                             width: (maxX - minX).rounded(.up),
                                             height: segmentHeight))
      segmentView.tag = segmentsTag
      segmentView.backgroundColor = .systemTeal
      view.addSubview(segmentView)
    }
  }
  
  @objc func displayStep(_ displaylink: CADisplayLink) {
    let actualFramesPerSecond = 1 / (displaylink.targetTimestamp - displaylink.timestamp)
    currentFps = actualFramesPerSecond.rounded()
    expandingSegment.frame = CGRect(x: expandingSegmentMinX,
                                    y: 0,
                                    width: expandingSegment.width + advanceRate,
                                    height: segmentHeight)
  }
}
