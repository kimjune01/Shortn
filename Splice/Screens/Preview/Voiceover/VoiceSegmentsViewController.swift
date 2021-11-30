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
  static let defaultHeight:CGFloat = 28
  private let expandingSegment = UIView()
  var expandingRate: CGFloat = 0
  var displayLink: CADisplayLink!
  var runningPortion: CGFloat = 0
  private var expanding = false {
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
    view.backgroundColor = .systemGray.withAlphaComponent(0.2)
    view.frame = .zero
    view.layer.cornerRadius = 3
    addExpandingSegment()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    subscribeToDisplayLink()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    displayLink?.invalidate()
  }
  
  func addExpandingSegment() {
    view.addSubview(expandingSegment)
    expandingSegment.backgroundColor = .systemRed.withAlphaComponent(0.6)
  }
  
  func renderFreshAssets() {
    guard composition.assets.count > 0 else { return }
    renderSegments()
  }
  
  func adjustExpandingRate() {
    expandingRate =  view.width / composition.totalDuration
  }
  
  func renderSegments() {
    // segments are spread out over total duration
    for eachSubview in view.subviews {
      if eachSubview != expandingSegment {
        eachSubview.removeFromSuperview()
      }
    }
    runningPortion = 0
    for eachVoice in composition.voiceSegments {
      let thisPortion: CGFloat = eachVoice.duration.seconds / composition.totalDuration
      let newSegment = makeNewSegment(start: runningPortion, portion: thisPortion)
      view.addSubview(newSegment)
      runningPortion += thisPortion
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
  
  func startExpanding() {
    expanding = true
  }
  
  func stopExpanding() {
    print("stopExpanding")
    expanding = false
  }
  
  func subscribeToDisplayLink() {
    displayLink?.invalidate()
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
                                    width: timeSince * expandingRate,
                                    height: view.height)
    print("expandingSegment.width: ", expandingSegment.width)
  }
  
  func lastSegment() -> UIView? {
    return view.subviews.last
  }
}
