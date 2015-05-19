import UIKit

@IBDesignable
class RatingView: UIView {
    @IBOutlet weak var image0: UIImageView!
    @IBOutlet weak var image1: UIImageView!
    @IBOutlet weak var image2: UIImageView!
    @IBOutlet weak var image3: UIImageView!
    @IBOutlet weak var image4: UIImageView!
    
    @IBOutlet weak var oliveHeight: NSLayoutConstraint!
    @IBOutlet weak var oliveWidth: NSLayoutConstraint!
    
    @IBOutlet weak var view: UIView!
    
    var editing = false
    
    var rating = 0 {
        didSet {
            let images = [ image0, image1, image2, image3, image4 ]
            
            for i in 0..<rating {
                images[i].image = UIImage(named: "olive-paperclip-32.png")
            }
            
            for j in rating..<5 {
                images[j].image = UIImage(named: "olive3-pick only-32.png")
            }
        }
    }
    
    required init(coder aDecoder: NSCoder) {
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
        view.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "RatingView", bundle: bundle)
        
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        return view
    }
 
    func handleTouches(touches: Set<NSObject>) {
        if !editing {
            return
        }

        for touch in touches as! Set<UITouch> {
            let touchLocation = touch.locationInView(self)

            let images = [ image0, image1, image2, image3, image4 ]

            var newRating: Int = 0
            for i in stride(from: images.count-1, through: 0, by: -1) {
                if touchLocation.x > images[i].frame.origin.x {
                    newRating = i + 1
                    break
                }
            }
            
            self.rating = newRating
        }
    }

    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        handleTouches(touches)
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        handleTouches(touches)
    }
}