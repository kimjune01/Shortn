//
//  BpmConfigViewController.swift
//  Shorten
//
//  Created by June Kim on 11/2/21.
//

import UIKit

protocol BpmConfigViewControllerDelegate: AnyObject {
  func didUpdate(config: BpmConfig)
}

// Full screen that configures
class BpmConfigViewController: UIViewController {
  
  var config: BpmConfig = BpmConfig.userDefault() {
    didSet {
      updateAppearance()
    }
  }
  weak var delegate: BpmConfigViewControllerDelegate?
  
  let stackView = UIStackView()
  let toggle = UISwitch()
  let bpmPicker = UIPickerView()
  let measurePicker = UIPickerView()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    addStackView()
    addToggle()
    addBpm()
    addMeasure()
    addSwipeToDismissLabel()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    delegate?.didUpdate(config: config)
    config.setAsDefault()
  }
  
  func addStackView() {
    view.addSubview(stackView)
    stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9).isActive = true
    stackView.centerXInParent()
    stackView.centerYInParent()
    stackView.distribution = .equalSpacing
    stackView.axis = .vertical
    stackView.spacing = 12
  }
  
  func addToggle() {
    let horizontal = makeHorizontalStack()
    let label = UILabel()
    label.text = "Turn on Visual Metronome"
    horizontal.addArrangedSubview(label)
    horizontal.addArrangedSubview(toggle)
    toggle.addTarget(self, action: #selector(switchedToggle), for: .valueChanged)
    toggle.isOn = config.isEnabled
  }
  
  func addBpm() {
    let horizontal = makeHorizontalStack()
    let label = UILabel()
    label.text = "Beats per minute"
    horizontal.addArrangedSubview(label)
    
    bpmPicker.dataSource = self
    bpmPicker.delegate = self
    horizontal.addArrangedSubview(bpmPicker)
    
    bpmPicker.set(width: 100)
    bpmPicker.selectRow(rowFor(bpm: config.bpm), inComponent: 0, animated: false)
  }
  
  func addMeasure() {
    let horizontal = makeHorizontalStack()
    let label = UILabel()
    label.text = "Beats per measure"
    horizontal.addArrangedSubview(label)
    
    measurePicker.dataSource = self
    measurePicker.delegate = self
    horizontal.addArrangedSubview(measurePicker)
    
    measurePicker.set(width: 100)
    measurePicker.selectRow(rowFor(measure: config.measure), inComponent: 0, animated: false)
  }
  
  func addSwipeToDismissLabel() {
    let blankView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 50))
    stackView.addArrangedSubview(blankView)
    
    let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.width * 0.7, height: 100))
    label.alpha = 0.9
    label.text = "Swipe down to dismiss\n↓"
    label.numberOfLines = 0
    label.textAlignment = .center
    stackView.addArrangedSubview(label)

  }
  
  func makeHorizontalStack() -> UIStackView {
    let horizontal = UIStackView()
    horizontal.axis = .horizontal
    horizontal.distribution = .equalSpacing
    stackView.addArrangedSubview(horizontal)
    horizontal.set(height: 49)
    horizontal.alignment = .center
    return horizontal
  }
  
  
  @objc func switchedToggle(_ toggle: UISwitch) {
    config.isEnabled = toggle.isOn
  }
  
  func rowFor(bpm: Int) -> Int {
    return BpmConfig.bpmOptions.firstIndex(of: bpm) ?? 0
  }
  func rowFor(measure: Int) -> Int {
    return BpmConfig.measureOptions.firstIndex(of: measure) ?? 0
  }
  
  func updateAppearance() {
    toggle.isOn = config.isEnabled
    bpmPicker.selectRow(rowFor(bpm: config.bpm), inComponent: 0, animated: false)
    measurePicker.selectRow(rowFor(measure: config.measure), inComponent: 0, animated: false)

  }
}

extension BpmConfigViewController: UIPickerViewDataSource, UIPickerViewDelegate {
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    switch pickerView {
    case bpmPicker:
      return BpmConfig.bpmOptions.count
    case measurePicker:
      return BpmConfig.measureOptions.count
    default:
      return 0
    }
  }
  
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    switch pickerView {
    case bpmPicker:
      return String(BpmConfig.bpmOptions[row])
    case measurePicker:
      return String(BpmConfig.measureOptions[row])
    default:
      return "."
    }
  }
  
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    switch pickerView {
    case bpmPicker:
      config.bpm = BpmConfig.bpmOptions[row]
    case measurePicker:
      config.measure = BpmConfig.measureOptions[row]
    default:
      break
    }
  }
}
