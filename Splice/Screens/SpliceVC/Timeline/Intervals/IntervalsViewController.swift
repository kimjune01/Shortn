//
//  IntervalsViewController.swift
//  Shortn
//
//  Created by June Kim on 11/21/21.
//

import UIKit
import QuartzCore

protocol IntervalsViewControllerDelegate: AnyObject {
  func intervalsVCDidSelectSegment(at index: Int)
  func intervalsVCDidSwipeUpSegment(at index: Int)
}

// Lives inside a scrollview, dynamically displays intervals
class IntervalsViewController: UIViewController {
  unowned var composition: SpliceComposition
  weak var delegate: IntervalsViewControllerDelegate?
  var intervals: [IntervalView] = []
  let expandingInterval = UIView()

  init(composition: SpliceComposition) {
    self.composition = composition
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    addExpandingInterval()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  override func didMove(toParent parent: UIViewController?) {
    super.didMove(toParent: parent)
  }
  
  func setFrame(_ frame: CGRect) {
    view.frame = frame
  }
  
  func addExpandingInterval() {
    expandingInterval.backgroundColor = IntervalView.expandingColor
    expandingInterval.roundCorner(radius: 3, cornerCurve: .continuous)
    expandingInterval.frame = .zero
    view.addSubview(expandingInterval)
  }
  
  func renderFreshAssets() {
    
  }
  
  func updateIntervalsForSplices() {
    for interval in intervals {
      interval.removeFromSuperview()
    }
    intervals = []
    let totalDuration = composition.totalDuration
    composition.splices.forEach { splice in
      let minX = splice.lowerBound * view.width / totalDuration
      let maxX = splice.upperBound * view.width / totalDuration
      let intervalView = IntervalView(frame: CGRect(x: minX.rounded(.down),
                                                  y: 0,
                                                  width: (maxX - minX).rounded(.up),
                                                  height: view.height))
      intervalView.addColor()
      intervalView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedInterval)))
      let swipeUpRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipedUpInterval))
      swipeUpRecognizer.direction = .up
      intervalView.addGestureRecognizer(swipeUpRecognizer)
      view.addSubview(intervalView)
      intervals.append(intervalView)
    }
  }
  
  func startExpandingInterval(startTime: TimeInterval) {
    let expandingIntervalMinX =  startTime * view.width / composition.totalDuration
    expandingInterval.frame = CGRect(x: expandingIntervalMinX, y: 0, width: 0, height: view.height)
    
    UIView.animate(withDuration: composition.totalDuration - startTime,
                   delay: 0,
                   options: [.curveLinear]) {
      self.expandingInterval.frame = CGRect(x: expandingIntervalMinX, y: 0,
                                            width: self.view.width - expandingIntervalMinX,
                                            height: self.view.height)
    }
  }
  
  func stopExpandingInterval() {
    self.expandingInterval.layer.removeAllAnimations()
    self.expandingInterval.frame = .zero
  }
  
  func deselectIntervals() {
    intervals.forEach{$0.isSelected = false}
  }
  
  @objc func tappedInterval(_ recognizer: UIGestureRecognizer) {
    guard let interval = recognizer.view as? IntervalView else { return }
    let maybeIndex = intervals.map{$0.minX}.sorted().firstIndex(of: interval.minX)
    guard let index = maybeIndex else { return }
    if interval.isSelected {
      delegate?.intervalsVCDidSelectSegment(at: index)
      return
    }
    for otherSegments in intervals {
      otherSegments.appearUnselected()
      otherSegments.isSelected = false
    }
    interval.appearSelected()
    interval.isSelected = true
  }
  
  @objc func swipedUpInterval(_ recognizer: UIGestureRecognizer) {
    guard let interval = recognizer.view as? IntervalView else { return }
    let maybeIndex = intervals.map{$0.minX}.sorted().firstIndex(of: interval.minX)
    guard let index = maybeIndex else { return }
    delegate?.intervalsVCDidSwipeUpSegment(at: index)

  }
}
