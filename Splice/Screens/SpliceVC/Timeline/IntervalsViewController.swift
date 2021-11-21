//
//  IntervalsViewController.swift
//  Shortn
//
//  Created by June Kim on 11/21/21.
//

import UIKit

protocol IntervalsViewControllerDelegate: AnyObject {
  func intervalsVCDidSelectSegment(at index: Int)
  func intervalsVCDidSwipeUpSegment(at index: Int)
}

// Lives inside a scrollview, dynamically displays intervals
class IntervalsViewController: UIViewController {
  unowned var composition: SpliceComposition

  init(composition: SpliceComposition) {
    self.composition = composition
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
  }
}
