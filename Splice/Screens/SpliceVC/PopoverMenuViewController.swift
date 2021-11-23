//
//  PopoverMenuViewController.swift
//  Shortn
//
//  Created by June Kim on 11/22/21.
//

import UIKit

protocol PopoverMenuViewControllerDelegate: AnyObject {
  func popoverVCDidTapLoopButton(_ popoverVC: PopoverMenuViewController)
  func popoverVCDidTapTrashButton(_ popoverVC: PopoverMenuViewController)
  func popoverVCDidDisappear(_ popoverVC: PopoverMenuViewController)
}

class PopoverMenuViewController: UIViewController {
  static let preferredSize = CGSize(width: 90, height: 45)
  weak var delegate: PopoverMenuViewControllerDelegate?
  
  let stackView = UIStackView()
  var loopButton: UIButton!
  var trashButton: UIButton!
  var isPresentable: Bool {
    return viewIfLoaded?.window == nil
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    addStackView()
    addButtons()
    view.backgroundColor = .white.withAlphaComponent(0.2)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    delegate?.popoverVCDidDisappear(self)
  }
  
  func addStackView() {
    stackView.backgroundColor = .clear
    view.addSubview(stackView)
    stackView.axis = .horizontal
    stackView.contentMode = .center
    stackView.alignment = .center
    stackView.distribution = .fillEqually
    stackView.fillParent()
  }
  
  func addButtons() {
    var loopConfig = UIButton.Configuration.plain()
    loopConfig.image = UIImage(systemName: "arrow.2.circlepath")
    loopButton = UIButton(configuration: loopConfig, primaryAction: UIAction(handler: { [weak self] action in
      guard let self = self else { return }
      self.delegate?.popoverVCDidTapLoopButton(self)
    }))
    stackView.addArrangedSubview(loopButton)
    
    var trashConfig = UIButton.Configuration.plain()
    trashConfig.image = UIImage(systemName: "trash")
    trashConfig.baseForegroundColor = .systemPink
    trashButton = UIButton(configuration: trashConfig, primaryAction: UIAction(handler: { [weak self] action in
      guard let self = self else { return }
      self.delegate?.popoverVCDidTapTrashButton(self)
    }))
    stackView.addArrangedSubview(trashButton)
  }
  
  func highlightLoopButton() {
    loopButton.doGlowAnimation(withColor: .systemBlue.withAlphaComponent(0.7))
    loopButton.animateSwell(-0.05)
  }
  
  func unhighlightLoopButton() {
    loopButton.layer.removeAllAnimations()
  }
  
}
