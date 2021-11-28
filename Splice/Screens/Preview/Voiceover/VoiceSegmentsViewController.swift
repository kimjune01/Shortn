//
//  VoiceSegmentsViewController.swift
//  Shortn
//
//  Created by June Kim on 11/27/21.
//

import UIKit

//
class VoiceSegmentsViewController: UIViewController {
  unowned var composition: SpliceComposition
  weak var delegate: VoiceoverViewControllerDelegate?
  static let defaultHeight:CGFloat = 28
  let expandingSegment = UIView()
  var expandingRate: CGFloat = 0
  var displayLink: CADisplayLink!
  var runningPortion: CGFloat = 0
  var expanding = false {
    didSet {
      if expanding {
        expandingStartTime = Date()
      }
    }
  }
  var expandingStartTime: Date!

  init(composition: SpliceComposition) {
    self.composition = composition
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black.withAlphaComponent(0.2)
    view.layer.cornerRadius = 3
    addExpandingSegment()
    subscribeToDisplayLink()
  }
  
  func addExpandingSegment() {
    view.addSubview(expandingSegment)
    expandingSegment.backgroundColor = .systemRed
  }
  
  func renderSegments() {
    // segments are spread out over total duration
    for eachSubview in view.subviews {
      eachSubview.removeFromSuperview()
    }
    runningPortion = 0
    for eachVoice in composition.voiceSegments {
      let thisPortion: CGFloat = eachVoice.duration.seconds / composition.totalDuration
      let newSegment = makeNewSegment(start: runningPortion, portion: thisPortion)
      view.addSubview(newSegment)
      runningPortion += thisPortion
    }
    if composition.totalDuration > 0 {
      expandingRate = view.width / composition.totalDuration
    }
  }
  
  func makeNewSegment(start: CGFloat, portion: CGFloat) -> UIView{
    let segment = UIView(frame: CGRect(x: start * view.width,
                                y: 0,
                                width: portion * view.width,
                                height: view.height))
    segment.backgroundColor = .systemBlue
    segment.layer.cornerRadius = 4
    return segment
  }
  
  func subscribeToDisplayLink() {
    displayLink = CADisplayLink(target: self, selector: #selector(displayStep))
    displayLink.isPaused = false
    displayLink.add(to: .main, forMode: .common)
  }
  
  @objc func displayStep() {
    guard expanding else {
      expandingSegment.isHidden = true
      return
    }
    expandingSegment.isHidden = false
    let timeSince: CGFloat = abs(Date().timeIntervalSinceReferenceDate - expandingStartTime.timeIntervalSinceReferenceDate)
    expandingSegment.frame = CGRect(x: runningPortion * view.width,
                                    y: 0,
                                    width: timeSince * view.width,
                                    height: view.height)
  }
}
