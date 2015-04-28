import UIKit

class RecipeViewController: UIViewController {
    var recipe: Recipe?
    
    @IBOutlet weak var recipeTextView: UITextView!
    
    @IBOutlet weak var recipeTextViewHeight: NSLayoutConstraint!
    @IBOutlet weak var ratingView: RatingView!
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = recipe!.name
        
        let sortedComponents = Component.sorted(recipe!.components)
        let componentText = "\n".join(map(sortedComponents, { $0.string }))
        recipeTextView!.text = "\(componentText)\n\n\(recipe!.text)"
        ratingView!.rating = Int(recipe!.rating)
        
        let fit = recipeTextView.sizeThatFits(recipeTextView.contentSize)
        recipeTextViewHeight.constant = fit.height + 64 // FIXME: 64??
        
        recipeTextView.setNeedsUpdateConstraints()

        //http://stackoverflow.com/questions/27652334/uitextview-inside-uiscrollview-with-autolayout
    }
}
