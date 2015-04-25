import UIKit

class AddRecipeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!

    @IBOutlet weak var recipeName: UITextField!
    @IBOutlet weak var componentTable: UITableView!

    var added = false
    var recipe: Recipe?
    var components: [Component] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recipe = Recipe.create("", withRating: 1, withText: "", inContext: moc)

        componentTable!.dataSource = self
        componentTable!.delegate = self
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return components.count + 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        if indexPath.row == components.count {
            cell = componentTable.dequeueReusableCellWithIdentifier("addComponentCell") as! UITableViewCell
        } else {
            cell = componentTable.dequeueReusableCellWithIdentifier("componentCell") as! UITableViewCell
            cell.textLabel!.text = components[indexPath.row].string
        }
        
//        recipeComponentTableView.sizeToFit()
        
        return cell
    }


    @IBAction func onDone(sender: UIBarButtonItem) {
        recipe!.name = recipeName!.text
        recipe!.component_count = Int16(components.count)
        
        var error: NSError?
        if moc.save(&error) {
            added = true
            performSegueWithIdentifier("unwindToRecipes", sender: self)
        } else {
            // FIXME: alert!
            NSLog("\(error)")
        }
    }
    
    @IBAction func unwindToAddRecipe(sender: UIStoryboardSegue)
    {
        if let vc = sender.sourceViewController as? AddIngredientToComponentViewController {
        } else if let vc = sender.sourceViewController as? AddQuantityToComponentViewController {
            if let unit = vc.unit {
                let u = Unit.find("ounce", context: moc)
                let c = Component.create(1, quantity_d: 1, unit: unit, ingredient: vc.ingredient!, recipe: recipe!, context: moc)
                c.ingredient.recipe_count += 1
                components.append(c)
                
                componentTable.reloadData()

            }
        }
    }
}
