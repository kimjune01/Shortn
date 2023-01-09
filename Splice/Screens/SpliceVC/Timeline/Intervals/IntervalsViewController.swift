//
//  IntervalsViewController.swift
//  Shortn
//
//  Created by June Kim on 11/21/21.
//

import UIKit
import QuartzCore

protocol IntervalsViewControllerDelegate: AnyObject {
  func timelineSize() -> CGSize
  func intervalsVCDidSelectInterval(at index: Int)
  func intervalsVCDidSwipeUpInterval(at index: Int)
  func intervalsVCDidModifyInterval(at index: Int, newSplice: Splice)
}

// Lives inside a scrollview, dynamically displays intervals
class IntervalsViewController: UIViewController {
  unowned var composition: SpliceComposition
  weak var delegate: IntervalsViewControllerDelegate?
  var intervals: [IntervalView] = []
  let expandingInterval = UIView()
  var currentlySelectedIndex: Int? = nil
  var pixelsPerSecond: CGFloat {
    return view.width / composition.totalDuration
  }

  init(composition: SpliceComposition) {
    self.composition = composition
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
//    view.backgroundColor = .systemPurple
    addExpandingInterval()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  override func didMove(toParent parent: UIViewController?) {
    super.didMove(toParent: parent)
    view.frame = CGRect(origin: .zero, size: delegate!.timelineSize())
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
    updateIntervalsForSplices()
  }
  
  func updateIntervalsForSplices() {
    for interval in intervals {
      interval.removeFromSuperview()
    }
    intervals = []
    let totalDuration = composition.totalDuration
    composition.splices.forEach { splice in
      let minX = splice.lowerBound * self.pixelsPerSecond
      let maxX = splice.upperBound * self.pixelsPerSecond
      let intervalView = IntervalView(frame: CGRect(x: minX.rounded(.down),
                                                  y: 0,
                                                  width: (maxX - minX).rounded(.up),
                                                  height: view.height))
      intervalView.assignedSplice = splice
      intervalView.delegate = self
      intervalView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedInterval)))
      let swipeUpRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipedUpInterval))
      swipeUpRecognizer.direction = .up
      intervalView.addGestureRecognizer(swipeUpRecognizer)
      view.addSubview(intervalView)
      intervals.append(intervalView)
    }
  }
  
  func startExpandingInterval(startTime: TimeInterval) {
    let expandingIntervalMinX =  startTime * pixelsPerSecond
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
    currentlySelectedIndex = nil
  }
  
  func setSelected(intervalIndex: Int?) {
    currentlySelectedIndex = intervalIndex
    for (idx, eachInterval) in intervals.enumerated() {
      if idx == intervalIndex {
        eachInterval.isSelected = true
      } else {
        eachInterval.isSelected = false
      }
    }
  }
  
  @objc func tappedInterval(_ recognizer: UIGestureRecognizer) {
    guard let interval = recognizer.view as? IntervalView else { return }
    let maybeIndex = intervals.map{$0.minX}.sorted().firstIndex(of: interval.minX)
    guard let index = maybeIndex else { return }
    
    // cannot deselect
    // order matters
    delegate?.intervalsVCDidSelectInterval(at: index)
    setSelected(intervalIndex: index)
  }
  
  @objc func swipedUpInterval(_ recognizer: UIGestureRecognizer) {
    guard let interval = recognizer.view as? IntervalView else { return }
    let maybeIndex = intervals.map{$0.minX}.sorted().firstIndex(of: interval.minX)
    guard let index = maybeIndex else { return }
    delegate?.intervalsVCDidSwipeUpInterval(at: index)

  }
}

extension IntervalsViewController: IntervalViewDelegate {
  func didFinishPanningLeftHandle(_ intervalView: IntervalView, leftPan: CGFloat) {
    let leftTimeDiff = leftPan / pixelsPerSecond
    if let oldSplice = intervalView.assignedSplice,
    let index = currentlySelectedIndex {
      let left = oldSplice.lowerBound + leftTimeDiff
      let right = oldSplice.upperBound
      let newSplice = min(left, right)...max(left, right)
      delegate?.intervalsVCDidModifyInterval(at: index, newSplice: newSplice)
    }
  }
  func didFinishPanningRightHandle(_ intervalView: IntervalView, rightPan: CGFloat) {
    let rightTimeDiff = rightPan / pixelsPerSecond
    print("rightTimeDiff: ", rightTimeDiff)
    if let oldSplice = intervalView.assignedSplice,
        let index = currentlySelectedIndex {
      let left = oldSplice.lowerBound
      let right = oldSplice.upperBound + rightTimeDiff
      let newSplice = min(left, right)...max(left, right)
      delegate?.intervalsVCDidModifyInterval(at: index, newSplice: newSplice)
    }
  }
}
