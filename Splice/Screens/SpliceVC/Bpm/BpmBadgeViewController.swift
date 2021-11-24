//
//  BpmViewController.swift
//  Shorten
//
//  Created by June Kim on 11/2/21.
//

import UIKit

enum BpmBadgeState {
  case stopped
  case ticking
}

// a tiny component to show the BPM when asked.
class BpmBadgeViewController: UIViewController {
  let composition: SpliceComposition
  
  static let width: CGFloat = 60
  static let height: CGFloat = 30
  
  var bpmTimer: BPMTimer!
  var config = BpmConfig.userDefault() {
    didSet {
      if config.isEnabled {
        state = .ticking
        composition.bpm = config.bpm
      } else {
        state = .stopped
        composition.bpm = nil
      }
      updateAppearance()
    }
  }
  
  var state: BpmBadgeState = .stopped
  
  let stoppedLabel = UILabel()
  let tickTockView = UIView()
  
  private var beatTracker = 0
  
  init(composition: SpliceComposition) {
    self.composition = composition
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.set(height: BpmBadgeViewController.height)
    view.set(width: BpmBadgeViewController.width)

    addTimer()
    addTickTockView()
    addStoppedLabel()
    addTouchTarget()
    self.config = BpmConfig.userDefault()
  }
  
  func addTimer() {
    bpmTimer = BPMTimer(bpm: Double(config.bpm))
    bpmTimer.delegate = self
    if config.isEnabled {
      bpmTimer.start()
    }
  }
  
  func addTickTockView() {
    view.addSubview(tickTockView)
    let circleSize: CGFloat = 12
    tickTockView.setSquare(constant: circleSize)
    tickTockView.roundCorner(radius: circleSize / 2, cornerCurve: .circular)
    tickTockView.backgroundColor = .white
    tickTockView.centerXInParent()
    tickTockView.centerYInParent()
    tickTockView.isUserInteractionEnabled = false
  }
  
  func addTouchTarget() {
    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedView)))
  }
  
  func addStoppedLabel() {
    view.addSubview(stoppedLabel)
    stoppedLabel.centerXInParent()
    stoppedLabel.centerYInParent()
    stoppedLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
    stoppedLabel.textColor = .white
    stoppedLabel.text = " "
    stoppedLabel.textAlignment = .center
  }
  
  func updateAppearance() {
    stoppedLabel.isHidden = state != .stopped
    tickTockView.isHidden = state != .ticking
    
    switch state {
    case .ticking:
      bpmTimer.bpm = Double(config.bpm)
      bpmTimer.start()
    case .stopped:
      bpmTimer.stop()
    }
  }
  
  @objc func tappedView() {
    if state == .ticking {
      config.isEnabled = false
      config.setAsDefault()
    } else {
      let bpmConfigVC = BpmConfigViewController()
      bpmConfigVC.delegate = self
      present(bpmConfigVC, animated: true)
    }
  }
  
  func tick() {
    tickTockView.alpha = 1
    UIView.animate(withDuration: 60 / Double(config.bpm), delay: 0, options: [.curveEaseOut]) {
      self.tickTockView.alpha = 0.25
    }
  }
  
  func tock() {
    tickTockView.alpha = 1
    tickTockView.transform = CGAffineTransform(scaleX: 1.6, y: 1.6)
    UIView.animate(withDuration: 60 / Double(config.bpm), delay: 0, options: [.curveEaseOut]) {
      self.tickTockView.alpha = 0.25
      self.tickTockView.transform = CGAffineTransform(scaleX: 1, y: 1)
    }
  }
}

extension BpmBadgeViewController: BPMTimerDelegate {
  func bpmTimerTicked() {
    beatTracker += 1
    if beatTracker % config.measure == 0 {
      tock()
    } else {
      tick()
    }
  }
}

extension BpmBadgeViewController: BpmConfigViewControllerDelegate {
  func didUpdate(config: BpmConfig) {
    self.config = config
  }
}
