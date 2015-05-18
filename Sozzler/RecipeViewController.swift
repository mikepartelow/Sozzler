import UIKit

class RecipeViewController: UIViewController {
    var recipe: Recipe?
    
    @IBOutlet weak var recipeTextView: UITextView!
    
    @IBOutlet weak var recipeTextViewHeight: NSLayoutConstraint!
    @IBOutlet weak var ratingView: RatingView!
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = recipe!.name
        
        let sortedComponents = recipe!.sortedComponents
        let componentText = "\n".join(map(sortedComponents, { $0.string }))
        recipeTextView!.text = "\(componentText)\n\n\(recipe!.text)"
        ratingView!.rating = Int(recipe!.rating)
        
        let fit = recipeTextView.sizeThatFits(recipeTextView.contentSize)
        recipeTextViewHeight.constant = fit.height + 84 // FIXME: magic number
        
        recipeTextView.setNeedsUpdateConstraints()

        //http://stackoverflow.com/questions/27652334/uitextview-inside-uiscrollview-with-autolayout
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editRecipe" {
            let nav = segue.destinationViewController as! UINavigationController
            let addRecipeViewController = nav.topViewController as! AddRecipeViewController
            
            addRecipeViewController.recipe = recipe
        }
    }
}
