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

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let deleteAction = UITableViewRowAction(style: .Default, title: "Delete") { (action, indexPath) -> Void in
            let component = self.components.removeAtIndex(indexPath.row)
            self.moc.deleteObject(component)
            self.componentTable.reloadData()

            tableView.editing = false
        }
        
        return [ deleteAction ]
    }

    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // even if it does nothing this needs to be here if we want to get a delete event
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
                let quantity_d = Int16(vc.quantity_f![1])
                let quantity_n = Int16((vc.quantity_f![1] * vc.quantity_i!) + vc.quantity_f![0])
                
                let c = Component.create(quantity_n, quantity_d: quantity_d, unit: unit, ingredient: vc.ingredient!, recipe: recipe!, context: moc)
                c.ingredient.recipe_count += 1
                components.append(c)
                
                componentTable.reloadData()

            }
        }
    }
}
