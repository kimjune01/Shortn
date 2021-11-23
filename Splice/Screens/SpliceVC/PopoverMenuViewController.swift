//
//  PopoverMenuViewController.swift
//  Shortn
//
//  Created by June Kim on 11/22/21.
//

import UIKit

class PopoverMenuViewController: UIViewController {
  static let preferredSize = CGSize(width: 90, height: 45)
  
  let stackView = UIStackView()
  var loopButton: UIButton!
  var trashButton: UIButton!
  var isPresentable: Bool {
    return !(isViewLoaded && view.window != nil)
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
    loopButton = UIButton(configuration: loopConfig, primaryAction: UIAction(handler: { action in
      print("loop action")
    }))
    stackView.addArrangedSubview(loopButton)
    
    var trashConfig = UIButton.Configuration.plain()
    trashConfig.image = UIImage(systemName: "trash")
    trashButton = UIButton(configuration: trashConfig, primaryAction: UIAction(handler: { action in
      print("trash action")
    }))
    stackView.addArrangedSubview(trashButton)
  }
  
}
