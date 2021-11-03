// https://stackoverflow.com/questions/42092907/how-to-make-uislider-default-thumb-to-be-smaller-like-the-ones-in-the-ios-contro

import UIKit

class CustomSlider: UISlider {
  static let defaultHeight: CGFloat = 10
  
  @IBInspectable var trackHeight: CGFloat = CustomSlider.defaultHeight
  @IBInspectable var thumbRadius: CGFloat = 20
  
  // Custom thumb view which will be converted to UIImage
  // and set as thumb. You can customize it's colors, border, etc.
  private lazy var thumbView: UIView = {
    let thumb = UIView()
    thumb.backgroundColor = .white//thumbTintColor
    thumb.layer.borderWidth = 0.4
    thumb.layer.borderColor = UIColor.darkGray.cgColor
    return thumb
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    let thumb = thumbImage(radius: thumbRadius)
    setThumbImage(thumb, for: .normal)
    tintColor = .darkGray.withAlphaComponent(0.2)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func thumbImage(radius: CGFloat) -> UIImage {
    // Set proper frame
    // y: radius / 2 will correctly offset the thumb
    let thumbContainer = UIView(frame: CGRect(x: 0, y: radius, width: radius * 2, height: radius * 2))
    thumbView.frame = CGRect(x: 0, y: 0, width: radius, height: radius)
    thumbView.layer.cornerRadius = radius / 2
    thumbContainer.addSubview(thumbView)
    thumbView.center = CGPoint(x: thumbContainer.width / 2, y: thumbContainer.height / 2)

    // Convert thumbView to UIImage
    // See this: https://stackoverflow.com/a/41288197/7235585
    
    let renderer = UIGraphicsImageRenderer(bounds: thumbContainer.bounds)
    return renderer.image { rendererContext in
      thumbContainer.layer.render(in: rendererContext.cgContext)
    }
  }
  
  override func trackRect(forBounds bounds: CGRect) -> CGRect {
    // Set custom track height
    // As seen here: https://stackoverflow.com/a/49428606/7235585
    let margin: CGFloat = 0
    return CGRect(x: margin,
                  y: (bounds.height - trackHeight)/2,
                  width: bounds.width - margin * 2,
                  height: trackHeight)
  }
  
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    let hitView = super.hitTest(point, with: event)
    // HAX
    if let sliderImage = subviews.last?.subviews.last, sliderImage.frame.contains(point) {
      return hitView
    }
    return nil
  }
}
