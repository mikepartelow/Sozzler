import UIKit

class RecipeViewController: UIViewController {
    var recipe: Recipe?
    
    @IBOutlet weak var recipeName: UILabel!
    @IBOutlet weak var recipeTextView: UITextView!
    
    @IBOutlet weak var recipeTextViewHeight: NSLayoutConstraint!
    @IBOutlet weak var ratingView: RatingView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataReset", name: "data.reset", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver("data.reset")
    }
    
    func dataReset() {
        performSegueWithIdentifier("unwindToRecipes", sender: nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        recipeName!.text = recipe!.name
        
        let sortedComponents = recipe!.sortedComponents
        let componentText = "\n".join(map(sortedComponents, { $0.string }))
        recipeTextView!.text = "\(componentText)\n\n\(recipe!.text)"
        ratingView!.rating = Int(recipe!.rating)
        
        let fit = recipeTextView.sizeThatFits(recipeTextView.contentSize).height
        recipeTextViewHeight.constant = fit
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editRecipe" {
            let nav = segue.destinationViewController as! UINavigationController
            let addRecipeViewController = nav.topViewController as! AddRecipeViewController
            
            addRecipeViewController.recipe = recipe
        }
    }
    
    @IBAction func unwindToRecipe(sender: UIStoryboardSegue)
    {
    }    
}
