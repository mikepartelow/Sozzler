import UIKit

class AddRecipeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {
    let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!

    @IBOutlet weak var recipeName: UITextField!
    @IBOutlet weak var componentTable: UITableView!
    @IBOutlet weak var componentTableHeight: NSLayoutConstraint!

    @IBOutlet weak var ratingView: RatingView!
    @IBOutlet weak var recipeText: UITextView!
    
    @IBOutlet weak var ratingStepper: UIStepper!
    let recipeTextPlaceholder = "Stir with ice, strain into chilled rocks glass."
    
    var added = false
    var recipe: Recipe?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if recipe == nil {
            recipe = Recipe.create("", withRating: 0, withText: "")
            recipeText.text = recipeTextPlaceholder
            recipeText.textColor = UIColor.lightGrayColor()
        } else {
            recipeName!.text = recipe!.name
            recipeText!.text = recipe!.text
            ratingView!.rating = Int(recipe!.rating)
        }

        recipeName.autocapitalizationType = UITextAutocapitalizationType.Words

        componentTable!.dataSource = self
        componentTable!.delegate = self
        recipeText.delegate = self
        
        ratingStepper!.value = Double(recipe!.rating)
    }
    
    @IBAction func onRatingStep(sender: UIStepper) {
        let rating = Int16(sender.value)
        recipe!.rating = rating
        ratingView!.rating = Int(rating)
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        if textView == recipeText {
            if recipeText!.text == recipeTextPlaceholder {
                recipeText!.text = ""
                recipeText!.textColor = UIColor.blackColor()
            }
        }
    }

    func textViewDidEndEditing(textView: UITextView) {
        if textView == recipeText {
            if recipeText!.text.isEmpty {
                recipeText!.text = recipeTextPlaceholder
                recipeText!.textColor = UIColor.lightGrayColor()
            }
        }
    }

    func resizeComponentsTable() {
        NSLog("\(componentTable.contentSize.height)")
        let height = CGFloat(min(44*8, max(44, componentTable.contentSize.height))) // FIXME: wtf magic number
        componentTableHeight.constant = height
        componentTable.setNeedsUpdateConstraints()
        // don't change this too much or https://trello.com/c/l4EfQLaI/86-add-9-ingredients-to-recipe-components-table-freaks-out
        componentTable.scrollToRowAtIndexPath(NSIndexPath(forItem: recipe!.components.count, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
    }

    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recipe!.components.count + 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        if indexPath.row == recipe!.components.count {
            cell = componentTable.dequeueReusableCellWithIdentifier("addComponentCell") as! UITableViewCell
        } else {
            cell = componentTable.dequeueReusableCellWithIdentifier("componentCell") as! UITableViewCell
            cell.textLabel!.text = recipe!.components.allObjects[indexPath.row].string
        }
        
        // FIXME: not happy with doing this here, very brute force. But anyhwere else and "edit recipe" involves equally ugly contortions.
        //
        // FIXME: this is the cause of https://trello.com/c/l4EfQLaI/86-add-9-ingredients-to-recipe-components-table-freaks-out
        resizeComponentsTable()
        
        return cell
    }

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let deleteAction = UITableViewRowAction(style: .Default, title: "Delete") { (action, indexPath) -> Void in
            let component = self.recipe!.components.allObjects[indexPath.row] as! Component
            
            self.recipe!.components.removeObject(component)
            
            CoreDataHelper.delete(component)
            
            self.componentTable.reloadData()
            
            tableView.editing = false
        }
        
        return [ deleteAction ]
    }

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.row < recipe!.components.count
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // even if it does nothing this needs to be here if we want to get a delete event
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "addIngredient" {
            let index = componentTable.indexPathForSelectedRow()!            
            componentTable.deselectRowAtIndexPath(index, animated: false)
        }
    }

    @IBAction func onDone(sender: UIBarButtonItem) {
        recipe!.name = recipeName!.text
        recipe!.text = recipeText!.text
        
        var error: NSError?
        if moc.save(&error) {
            added = true
            performSegueWithIdentifier("unwindToRecipes", sender: self)
        } else {
            // FIXME: on error, name edit is cleared out. don't do that.
            
            NSLog("\(error)")
            let errorMessage = error!.userInfo![NSLocalizedDescriptionKey] as! String
            var alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .Alert)
            let cancelAction = UIAlertAction(title: "Oops", style: .Default) { (action: UIAlertAction!) -> Void in }
            alert.addAction(cancelAction)
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func unwindToAddRecipe(sender: UIStoryboardSegue)
    {
        if let vc = sender.sourceViewController as? AddIngredientToComponentViewController {
        } else if let vc = sender.sourceViewController as? AddQuantityToComponentViewController {
            if let unit = vc.unit {
                // FIXME: should Component.create take [Int,Int] to put this logic in Component?
                let quantity_d = Int16(vc.quantity_f![1])
                let quantity_n = Int16((vc.quantity_f![1] * vc.quantity_i!) + vc.quantity_f![0])
                
                Component.create(quantity_n, quantity_d: quantity_d, unit: unit, ingredient: vc.ingredient!, recipe: recipe!)
                
                componentTable.reloadData()
            }
        }
    }
}
