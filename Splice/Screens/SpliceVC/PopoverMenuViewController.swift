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

enum PopoverView {
  case loopButton
  case trashButton
  case tutorial(String)
}

class PopoverMenuViewController: UIViewController {
  weak var delegate: PopoverMenuViewControllerDelegate?
  let viewsToInclude: [PopoverView]
  var preferredSize: CGSize {
    var runWidth: CGFloat = 0
    for included in viewsToInclude {
      switch included {
      case .loopButton:
        runWidth += 45
      case .trashButton:
        runWidth += 45
      case .tutorial(let text):
        let label = tutorialLabel(from: text)
        runWidth += label.width + 18
      }
    }
    return CGSize(width: runWidth, height: 45)
  }

  let stackView = UIStackView()
  var loopButton: UIButton!
  var trashButton: UIButton!
  var isPresentable: Bool {
    return viewIfLoaded?.window == nil
  }
  
  init(views: [PopoverView]) {
    self.viewsToInclude = views
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
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
  
  func tutorialLabel(from text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .systemFont(ofSize: 14, weight: .medium)
    label.sizeToFit()
    label.textAlignment = .center
    return label
  }
  
  func addButtons() {
    for included in viewsToInclude {
      switch included {
      case .loopButton:
        var loopConfig = UIButton.Configuration.plain()
        loopConfig.image = UIImage(systemName: "arrow.2.circlepath")
        loopButton = UIButton(configuration: loopConfig, primaryAction: UIAction(handler: { [weak self] action in
          guard let self = self else { return }
          self.delegate?.popoverVCDidTapLoopButton(self)
        }))
        stackView.addArrangedSubview(loopButton)
      case .trashButton:
        var trashConfig = UIButton.Configuration.plain()
        trashConfig.image = UIImage(systemName: "trash")
        trashConfig.baseForegroundColor = .systemPink
        trashButton = UIButton(configuration: trashConfig, primaryAction: UIAction(handler: { [weak self] action in
          guard let self = self else { return }
          self.delegate?.popoverVCDidTapTrashButton(self)
        }))
        stackView.addArrangedSubview(trashButton)
      case .tutorial(let text):
        let label = tutorialLabel(from: text)
        stackView.addArrangedSubview(label)
      }
    }
    
  }
  
  func highlightLoopButton() {
    loopButton.doGlowAnimation(withColor: .systemBlue.withAlphaComponent(0.7))
    loopButton.animateSwell(-0.05)
  }
  
  func unhighlightLoopButton() {
    loopButton.layer.removeAllAnimations()
  }
  
}
