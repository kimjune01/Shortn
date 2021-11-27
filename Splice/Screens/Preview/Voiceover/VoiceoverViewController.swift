//
//  VoiceoverViewController.swift
//  Shortn
//
//  Created by June Kim on 11/26/21.
//

import UIKit

protocol VoiceoverViewControllerDelegate: AnyObject {
  func playerFrame() -> CGRect
  func voiceoverVCDidCancel()
  func voiceoverVCDidFinish()
}

enum VoiceoverState: Int, CaseIterable, CustomDebugStringConvertible {
  case initial
  case recording
  case playback
  case paused
  case standby // at the tip
  case complete
  
  var debugDescription: String {
    switch self {
    case .initial: return "initial"
    case .recording: return "recording"
    case .playback: return "playback"
    case .paused: return "paused"
    case .standby: return "standby"
    case .complete: return "complete"
    }
  }
}

class VoiceoverViewController: UIViewController {
  unowned var composition: SpliceComposition
  weak var delegate: VoiceoverViewControllerDelegate?
  var state: VoiceoverState = .initial {
    didSet {
      updateAppearance()
    }
  }
  let transitionDuration: TimeInterval = 0.3
  let bottomStack = UIStackView()
  var micButton: UIButton!
  var undoButton: UIButton!
  var rewindButton: UIButton!
  var confirmButton: UIButton!
  var stateBorder = TouchlessView()
  var lookAheadThumbnail = UIImageView()
  var playerFrame: CGRect {
    if let delegate = delegate {
      return delegate.playerFrame()
    }
    return .zero
  }
  let playerControlStack = UIStackView()
  let debugButton = UIButton()

  init(composition: SpliceComposition) {
    self.composition = composition
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    addBottomStack()
    addStateBorder()
    addLookAheadThumbnail()
    addPlayerControlStack()
    
    addDebugButton()
  }
  
  func addBottomStack() {
    view.addSubview(bottomStack)
    bottomStack.set(height: UIStackView.bottomHeight)
    bottomStack.fillWidthOfParent(withDefaultMargin: true)
    
    bottomStack.pinBottomToParent(margin: 24, insideSafeArea: true)
    // for animations
    bottomStack.transform = .identity.translatedBy(x: 0, y: 100)
    bottomStack.distribution = .equalSpacing
    bottomStack.axis = .horizontal
    bottomStack.alignment = .center
    
    var backConfig = UIButton.Configuration.filled()
    backConfig.baseForegroundColor = .white
    backConfig.baseBackgroundColor = .black.withAlphaComponent(0.2)
    backConfig.buttonSize = .large
    backConfig.image = UIImage(systemName: "chevron.left")
    backConfig.baseForegroundColor = .white
    let backButton = UIButton(configuration: backConfig, primaryAction: UIAction(){ _ in
      self.delegate?.voiceoverVCDidCancel()
    })
    bottomStack.addArrangedSubview(backButton)
    
    var undoConfig = UIButton.Configuration.gray()
    undoConfig.baseForegroundColor = .white
    undoConfig.cornerStyle = .large
    undoConfig.buttonSize = .large
    undoConfig.image = UIImage(systemName: "delete.left")
    undoConfig.baseForegroundColor = .white
    undoButton = UIButton(configuration: undoConfig, primaryAction: UIAction(){ _ in
      self.tappedUndoButton()
    })
    bottomStack.addArrangedSubview(undoButton)
    
    var micConfig = UIButton.Configuration.filled()
    micConfig.baseForegroundColor = .white
    micConfig.baseBackgroundColor = .systemBlue
    micConfig.cornerStyle = .capsule
    micConfig.buttonSize = .large
    micConfig.image = UIImage(systemName: "mic.fill")
    micConfig.baseForegroundColor = .white
    micButton = UIButton(configuration: micConfig)
    bottomStack.addArrangedSubview(micButton)
    micButton.addTarget(self, action: #selector(touchDownMicButton), for: .touchDown)
    micButton.addTarget(self, action: #selector(touchDoneMicButton), for: .touchUpInside)
    micButton.addTarget(self, action: #selector(touchDoneMicButton), for: .touchDragOutside)
    
    micButton.set(height:47)
    micButton.set(width:110)
//    spliceButton.roundCorner(radius: 47 / 2, cornerCurve: .circular)
    
    var confirmConfig = UIButton.Configuration.filled()
    confirmConfig.baseForegroundColor = .white
    confirmConfig.baseBackgroundColor = .black.withAlphaComponent(0.2)
    confirmConfig.buttonSize = .large
    confirmConfig.image = UIImage(systemName: "checkmark")
    confirmButton = UIButton(configuration: confirmConfig, primaryAction: UIAction(){ _ in
      self.delegate?.voiceoverVCDidFinish()
    })
    bottomStack.addArrangedSubview(confirmButton)
  }
  
  func addStateBorder() {
    view.addSubview(stateBorder)
    stateBorder.alpha = 0
    stateBorder.layer.borderWidth = 3
  }
  
  func addLookAheadThumbnail() {
    view.addSubview(lookAheadThumbnail)
    lookAheadThumbnail.backgroundColor = .black
    lookAheadThumbnail.alpha = 0
    lookAheadThumbnail.frame = CGRect(x: view.width, y: view.height / 2, width: .zero, height: .zero)
  }
  
  func addPlayerControlStack() {
    view.addSubview(playerControlStack)
    playerControlStack.alpha = 0
    playerControlStack.axis = .horizontal
    playerControlStack.alignment = .center
    playerControlStack.distribution = .equalSpacing
   
    var rewindConfig = UIButton.Configuration.plain()
    rewindConfig.baseForegroundColor = .white
    rewindConfig.buttonSize = .medium
    rewindConfig.image = UIImage(systemName: "arrow.uturn.backward")
    rewindButton = UIButton(configuration: rewindConfig, primaryAction: UIAction(){ _ in
      self.rewind()
    })
    playerControlStack.addArrangedSubview(rewindButton)
//    var forwardConfig = UIButton.Configuration.plain()
//    forwardConfig.baseForegroundColor = .white
//    forwardConfig.buttonSize = .medium
//    forwardConfig.image = UIImage(systemName: "forward.end.fill")
//    let forwardButton = UIButton(configuration: forwardConfig, primaryAction: UIAction(){ _ in
//      self.forward()
//    })
//    playerControlStack.addArrangedSubview(forwardButton)
  }
  
  func addDebugButton() {
    view.addSubview(debugButton)
    debugButton.backgroundColor = .secondarySystemFill
    debugButton.frame = CGRect(x: 50, y: 50, width: 150, height: 50)
    debugButton.setTitle("State", for: .normal)
    debugButton.addTarget(self, action: #selector(tappedDebugButton), for: .touchUpInside)
  }
  
  func animateIn() {
    state = .initial
    stateBorder.frame = playerFrame
    playerControlStack.frame = CGRect(x: playerFrame.minX,
                                      y: playerFrame.maxY,
                                      width: playerFrame.width, height: 40)
    playerControlStack.alpha = 0
    UIView.animate(withDuration: transitionDuration + 0.01) {
      self.bottomStack.transform = .identity
      self.lookAheadThumbnail.alpha = 1
      let scaleFactor: CGFloat = 0.8
      let playerFrame = self.playerFrame
      self.lookAheadThumbnail.frame = CGRect(x: playerFrame.maxX + playerFrame.width * (1 - scaleFactor) / 2,
                                             y: playerFrame.minY + playerFrame.height * (1 - scaleFactor) / 2,
                                             width: playerFrame.width * scaleFactor,
                                             height: playerFrame.height * scaleFactor)
      
    } completion: { _ in
      UIView.animate(withDuration: 0.2) {
        self.stateBorder.alpha = 1
        self.playerControlStack.alpha = 1
      }
    }
  }
  
  func animateOut() {
    stateBorder.alpha = 0
    playerControlStack.alpha = 0
    UIView.animate(withDuration: transitionDuration) {
      self.bottomStack.transform = .identity.translatedBy(x: 0, y: 100)
      self.stateBorder.alpha = 0
      self.lookAheadThumbnail.alpha = 0
      self.lookAheadThumbnail.frame = CGRect(x: self.view.width,
                                             y: self.view.height / 2,
                                             width: .zero, height: .zero)
    }
  }
  
  func updateAppearance() {
    switch state {
    case .initial:
      stateBorder.layer.borderColor = UIColor.systemGray.withAlphaComponent(0.5).cgColor
      micButton.isEnabled = false
      rewindButton.obscure()
    case .recording:
      stateBorder.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.7).cgColor
      micButton.isEnabled = true
      rewindButton.obscure()
    case .playback:
      micButton.isEnabled = false
      stateBorder.layer.borderColor = UIColor.systemGray.withAlphaComponent(0.5).cgColor
      rewindButton.clarify()
    case .paused:
      micButton.isEnabled = false
      stateBorder.layer.borderColor = UIColor.systemGray.withAlphaComponent(0.5).cgColor
      rewindButton.clarify()
    case .standby:
      stateBorder.layer.borderColor = UIColor.systemGray.withAlphaComponent(0.7).cgColor
      micButton.isEnabled = true
      rewindButton.clarify()
    case .complete:
      stateBorder.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.7).cgColor
      micButton.isEnabled = false
      rewindButton.clarify()
    }
  }
  
  func rewind() {
    
  }
  
  func forward() {
    
  }
  
  func tappedUndoButton() {
    
  }
  
  @objc func touchDownMicButton() {
    state = .recording
  }
  
  @objc func touchDoneMicButton() {
    state = .standby

  }
  
  @objc func tappedDebugButton() {
    state = VoiceoverState(rawValue: (state.rawValue + 1) % VoiceoverState.allCases.count)!
    debugButton.setTitle(state.debugDescription, for: .normal)
  }
}
