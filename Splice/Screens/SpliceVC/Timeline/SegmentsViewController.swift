//
//  SegmentsViewController.swift
//  Splice
//
//  Created by June Kim on 10/30/21.
//

import UIKit

protocol SegmentsViewControllerDelegate: AnyObject {
  func segmentsVCDidSelectSegment(at index: Int)
  func segmentsVCDidSwipeUpSegment(at index: Int)
  
}

class SegmentsViewController: UIViewController {
  unowned var composition: SpliceComposition
  weak var delegate: SegmentsViewControllerDelegate?
  var segments: [UIView] = []
  let expandingSegment = UIView()
  static let segmentHeight: CGFloat = CustomSlider.defaultHeight
  private var segmentHeight: CGFloat { return SegmentsViewController.segmentHeight}
  private var expandingSegmentMinX: CGFloat = 0
  var isSelectedTag = 1337

  init(composition: SpliceComposition) {
    self.composition = composition
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    expandingSegment.backgroundColor = .systemRed
    expandingSegment.roundCorner(radius: 3, cornerCurve: .continuous)
    expandingSegment.frame = CGRect(x: 0,
                                    y: 0,
                                    width: 0,
                                    height: segmentHeight)
    view.addSubview(expandingSegment)

  }
  
  func startExpandingSegment(time: TimeInterval) {
    expandingSegmentMinX = time * view.width / composition.totalDuration
  }
  
  func stopExpandingSegment() {
    expandingSegment.frame = CGRect(x: expandingSegmentMinX, y: 0, width: 0, height: segmentHeight)
  }
  
  func updateSegmentsForSplices() {
    for eachSubview in segments {
      eachSubview.removeFromSuperview()
    }
    segments = []
    let totalDuration = composition.totalDuration
    composition.splices.forEach { splice in
      let minX = splice.lowerBound * view.width / totalDuration
      let maxX = splice.upperBound * view.width / totalDuration
      let segmentView = UIView(frame: CGRect(x: minX.rounded(.down),
                                             y: 0,
                                             width: (maxX - minX).rounded(.up),
                                             height: segmentHeight))
      segmentView.backgroundColor = .systemBlue
      segmentView.roundCorner(radius: 3, cornerCurve: .continuous)
      segmentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedSegment)))
      let swipeUpRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipedUpSegment))
      swipeUpRecognizer.direction = .up
      segmentView.addGestureRecognizer(swipeUpRecognizer)
      view.addSubview(segmentView)
      segments.append(segmentView)
    }
  }
  
  @objc func tappedSegment(_ recognizer: UITapGestureRecognizer) {
    guard let segment = recognizer.view else { return }
    let maybeIndex = segments.map{$0.minX}.sorted().firstIndex(of: segment.minX)
    guard let index = maybeIndex else { return }
    if segment.tag == isSelectedTag {
      delegate?.segmentsVCDidSelectSegment(at: index)
    } else {
      for otherSegments in segments {
        otherSegments.stopGlowing()
        otherSegments.tag = 0
      }
      segment.startGlowing()
      segment.tag = isSelectedTag
    }
  }
  
  @objc func swipedUpSegment(_ recognizer: UISwipeGestureRecognizer) {
    guard let segment = recognizer.view else { return }
    let maybeIndex = segments.map{$0.minX}.sorted().firstIndex(of: segment.minX)
    guard let index = maybeIndex else { return }
    delegate?.segmentsVCDidSwipeUpSegment(at: index)

  }
  func expand(rate: CGFloat) {
    expandingSegment.frame = CGRect(x: expandingSegmentMinX,
                                    y: 0,
                                    width: expandingSegment.width + rate,
                                    height: segmentHeight)
  }
  
  func stopGlowing() {
    for eachSegment in segments {
      eachSegment.stopGlowing()
      eachSegment.tag = 0
    }
  }
}
