//
//  IntervalsViewController.swift
//  Shortn
//
//  Created by June Kim on 11/21/21.
//

import UIKit

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
    expandingInterval.backgroundColor = .systemRed
    expandingInterval.roundCorner(radius: 3, cornerCurve: .continuous)
    expandingInterval.frame = CGRect(x: 0,
                                     y: 0,
                                     width: 0,
                                     height: view.height)
    view.addSubview(expandingInterval)
  }
  
  func renderFreshAssets() {
    
  }
  
  func updateSegmentsForSplices() {
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
      intervalView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedSegment)))
      let swipeUpRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipedUpSegment))
      swipeUpRecognizer.direction = .up
      intervalView.addGestureRecognizer(swipeUpRecognizer)
      view.addSubview(intervalView)
      intervals.append(intervalView)
    }
  }
  
  @objc func tappedSegment() {
    
  }
  
  @objc func swipedUpSegment() {
    
  }
}
