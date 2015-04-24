import UIKit

class AddRecipeViewController: UIViewController {
    let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!

    @IBOutlet weak var recipeName: UITextField!
    var added = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func onDone(sender: UIBarButtonItem) {
        let oz = Unit.find("ounce", context: moc)!
        
        var artichoke = Ingredient.find("artichoke", context: moc)!
        var limeJuice = Ingredient.find("lime juice", context: moc)!
        
        var r = Recipe.create(recipeName!.text, withRating: 4, withText: "inconcievably worse than it sounds", inContext: moc)
        Component.create(2, quantity_d: 3, unit: oz, ingredient: artichoke, recipe: r, context: moc)
        Component.create(1, quantity_d: 2, unit: oz, ingredient: limeJuice, recipe: r, context: moc)
        r.component_count = 2
        
        artichoke.recipe_count += 1
        limeJuice.recipe_count += 1
        
        var error: NSError?
        if moc.save(&error) {
            added = true
            performSegueWithIdentifier("unwindToRecipes", sender: self)
        } else {
            // FIXME: alert!
            NSLog("\(error)")
        }
    }
}
