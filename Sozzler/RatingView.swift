import UIKit

@IBDesignable
class RatingView: UIView {
    let userSettings = (UIApplication.shared.delegate as! AppDelegate).userSettings

    @IBOutlet weak var image0: UIImageView!
    @IBOutlet weak var image1: UIImageView!
    @IBOutlet weak var image2: UIImageView!
    @IBOutlet weak var image3: UIImageView!
    @IBOutlet weak var image4: UIImageView!
    
    @IBOutlet weak var oliveHeight0: NSLayoutConstraint!
    @IBOutlet weak var oliveHeight1: NSLayoutConstraint!
    @IBOutlet weak var oliveHeight2: NSLayoutConstraint!
    @IBOutlet weak var oliveHeight3: NSLayoutConstraint!
    @IBOutlet weak var oliveHeight4: NSLayoutConstraint!
    
    var oliveHeight = 30 {
        didSet {
            oliveHeight0.constant = CGFloat(oliveHeight)
            oliveHeight1.constant = CGFloat(oliveHeight)
            oliveHeight2.constant = CGFloat(oliveHeight)
            oliveHeight3.constant = CGFloat(oliveHeight)
            oliveHeight4.constant = CGFloat(oliveHeight)
            
            self.needsUpdateConstraints()
            self.layoutIfNeeded()            
        }
    }
    
    @IBOutlet weak var view: UIView!
    
    var editing = false
    
    var rating = 0 {
        didSet {
            let images = [ image0, image1, image2, image3, image4 ]
            
            for i in 0..<rating {
                images[i]?.image = UIImage(named: userSettings.oliveAsset)
            }
            
            for j in rating..<5 {
                images[j]?.image = UIImage(named: "asset-olive-white")
                // removing the unused images and resizing the frame might be better than this
                //
                images[j]?.image = images[j]?.image!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
                images[j]?.tintColor = UIColor.lightGray
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    func xibSetup() {
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        
        // for reference, not for looks!
//        view.layer.borderColor = UIColor.blackColor().CGColor
//        view.layer.borderWidth = CGFloat(1)

        addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "RatingView", bundle: bundle)
        
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView

        return view
    }
 
    func handleTouches(touches: Set<NSObject>) {
        if !editing {
            return
        }

        for touch in touches as! Set<UITouch> {
            let touchLocation = touch.location(in: self)

            let images = [ image0, image1, image2, image3, image4 ]

            var newRating: Int = 0
            for i in stride(from: images.count-1, through: 0, by: -1) {
                if touchLocation.x > (images[i]?.frame.origin.x)! {
                    newRating = i + 1
                    break
                }
            }
            
            self.rating = newRating
        }
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches: touches)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches: touches)
    }
}
