//
//  IntervalView.swift
//  Shortn
//
//  Created by June Kim on 11/21/21.
//

import UIKit

protocol IntervalViewDelegate: AnyObject {
  func didFinishPanningLeftHandle(_ intervalView:IntervalView, leftPan: CGFloat)
  func didFinishPanningRightHandle(_ intervalView:IntervalView, rightPan: CGFloat)
}

class IntervalView: UIView {
  var assignedSplice: Splice!
  weak var delegate: IntervalViewDelegate?
  var isSelected = false {
    didSet {
      if isSelected {
        appearSelected()
      } else {
        appearUnselected()
      }
    }
  }
  static let baseColor: UIColor = .systemBlue
  static let normalColor: UIColor = baseColor.withAlphaComponent(0.4)
  static let expandingColor: UIColor = .systemRed.withAlphaComponent(0.6)
  static let selectedColor: UIColor = baseColor.withAlphaComponent(0.5)
  
  var coloredArea = UIView()
  var leftHandle = UIView()
  var rightHandle = UIView()
  let handleWidth: CGFloat = 12
  
  var previousColoredAreaFrame: CGRect?
  var previousLeftHandleFrame: CGRect?
  var previousRightHandleFrame: CGRect?

  override init(frame: CGRect) {
    // artificially expand the frame to increase touch area for handles
    let expandedFrame = CGRect(x: frame.minX - handleWidth,
                               y: frame.minY,
                               width: frame.width + handleWidth * 2,
                               height: frame.height)
    super.init(frame: expandedFrame)
    addSubview(coloredArea)
    coloredArea.frame = CGRect(x: handleWidth, y: 0,
                                  width: frame.width,
                                  height: frame.height)
    makeHandles()
    addColor()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func makeHandles() {
    let boldConfig = UIImage.SymbolConfiguration(weight: .heavy)
    leftHandle.frame = CGRect(x: 0, y: 0,
                              width: handleWidth,
                              height: bounds.height)
    leftHandle.backgroundColor = .systemYellow
    leftHandle.isHidden = true
    leftHandle.roundClipLeftCorners(handleWidth)

    let leftArrow = UIImageView(frame: CGRect(x: 0, y: 0,
                                              width: leftHandle.width, height: leftHandle.width))
    leftArrow.image = UIImage(systemName: "chevron.left", withConfiguration: boldConfig)
    leftArrow.center = CGPoint(x: leftHandle.width / 2, y: leftHandle.height / 2)
    leftArrow.tintColor = IntervalView.baseColor
    leftHandle.addSubview(leftArrow)
    addSubview(leftHandle)

    let leftPan = UIPanGestureRecognizer(target: self, action: #selector(didPanLeftHandle))
    leftHandle.addGestureRecognizer(leftPan)
    
    //

    rightHandle.frame = CGRect(x: bounds.maxX - handleWidth,
                               y: 0,
                               width: handleWidth,
                               height: bounds.height)
    rightHandle.backgroundColor = .systemYellow
    rightHandle.isHidden = true
    rightHandle.roundClipRightCorners(handleWidth)

    let rightArrow = UIImageView(frame: CGRect(x: 0, y: 0,
                                               width: rightHandle.width, height: rightHandle.width))
    rightArrow.image = UIImage(systemName: "chevron.right", withConfiguration: boldConfig)
    rightArrow.center = CGPoint(x: rightHandle.width / 2, y: rightHandle.height / 2)
    rightArrow.tintColor = IntervalView.baseColor
    rightHandle.addSubview(rightArrow)
    addSubview(rightHandle)

    let rightPan = UIPanGestureRecognizer(target: self, action: #selector(didPanRightHandle))
    rightHandle.addGestureRecognizer(rightPan)
  }
  
  @objc func didPanLeftHandle(_ panRecognizer: UIPanGestureRecognizer) {
    let panX =  panRecognizer.translation(in: panRecognizer.view).x
    switch panRecognizer.state {
    case .began:
      previousColoredAreaFrame = coloredArea.frame
      previousLeftHandleFrame = leftHandle.frame
    case .changed:
      guard let prevColored = previousColoredAreaFrame else { return }
      let boundedPanX = min(prevColored.width, panX)
      coloredArea.frame = CGRect(x: prevColored.minX + boundedPanX,
                                 y: prevColored.minY,
                                 width: prevColored.width - boundedPanX,
                                 height: prevColored.height)
      guard let prevLeft = previousLeftHandleFrame else { return }
      leftHandle.frame = CGRect(x: prevLeft.minX + boundedPanX,
                                y: prevLeft.minY,
                                width: prevLeft.width,
                                height: prevLeft.height)
    case .ended:
      guard let prevColored = previousColoredAreaFrame else { return }
      let boundedPanX = min(prevColored.width, panX)
      delegate?.didFinishPanningLeftHandle(self, leftPan: boundedPanX)
    default:
      break
    }
  }
  
  @objc func didPanRightHandle(_ panRecognizer: UIPanGestureRecognizer) {
    let panX =  panRecognizer.translation(in: panRecognizer.view).x
    switch panRecognizer.state {
    case .began:
      previousColoredAreaFrame = coloredArea.frame
      previousRightHandleFrame = rightHandle.frame
    case .changed:
      guard let prevColored = previousColoredAreaFrame else { return }
      let boundedPanX = max(-prevColored.width, panX)
      coloredArea.frame = CGRect(x: prevColored.minX,
                                 y: prevColored.minY,
                                 width: prevColored.width + boundedPanX,
                                 height: prevColored.height)
      guard let preRight = previousRightHandleFrame else { return }
      rightHandle.frame = CGRect(x: preRight.minX + boundedPanX,
                                y: preRight.minY,
                                width: preRight.width,
                                height: preRight.height)
    case .ended:
      guard let prevColored = previousColoredAreaFrame else { return }
      let boundedPanX = max(-prevColored.width, panX)
      delegate?.didFinishPanningRightHandle(self, rightPan: boundedPanX)
    default:
      break
    }
  }
  
  func appearSelected() {
    coloredArea.backgroundColor = IntervalView.selectedColor
    doGlowAnimation(withColor: .white, withEffect: .normal)
    showHandles()
  }

  func appearUnselected() {
    layer.removeAllAnimations()
    coloredArea.backgroundColor = IntervalView.normalColor
    hideHandles()
  }
  
  func addColor() {
    coloredArea.backgroundColor = IntervalView.normalColor
    roundCorner(radius: 3, cornerCurve: .continuous)
  }
  
  func showHandles() {
    leftHandle.isHidden = false
    rightHandle.isHidden = false
    
    leftHandle.transform = .identity.translatedBy(x: handleWidth / 10, y: 0).scaledBy(x: 0.8, y: 1)
    rightHandle.transform = .identity.translatedBy(x: -handleWidth / 10, y: 0).scaledBy(x: 0.8, y: 1)
    leftHandle.alpha = 0.5
    rightHandle.alpha = 0.5
    UIView.animate(withDuration: 0.2) {
      self.leftHandle.transform = .identity
      self.rightHandle.transform = .identity
      self.leftHandle.alpha = 1
      self.rightHandle.alpha = 1
    }
  }
  
  func hideHandles() {
    leftHandle.isHidden = true
    rightHandle.isHidden = true
  }
  
  // employ the wider frame only when selected
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    if isSelected {
      return super.hitTest(point, with: event)
    } else {
      return coloredArea.frame.contains(point) ? super.hitTest(point, with: event) : nil
    }
  }
}
