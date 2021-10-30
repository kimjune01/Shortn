// https://stackoverflow.com/questions/29451162/how-to-accelerate-the-identification-of-a-single-tap-over-a-double-tap
import UIKit
import UIKit.UIGestureRecognizerSubclass

class ShortTapGestureRecognizer: UITapGestureRecognizer {
  // anything below 0.3 may cause doubleTap to be inaccessible by many users
  let tapMaxDelay: Double = 0.26
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesBegan(touches, with: event)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + tapMaxDelay) { [weak self] in
      if self?.state != .recognized {
        self?.state = .failed
      }
    }
  }
}
