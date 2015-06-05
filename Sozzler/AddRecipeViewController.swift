import UIKit
import CoreData

class AddRecipeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {
    let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!

    @IBOutlet weak var recipeName: UITextField!
    @IBOutlet weak var componentTable: UITableView!
    @IBOutlet weak var componentTableHeight: NSLayoutConstraint!

    @IBOutlet weak var ratingView: RatingView!
    @IBOutlet weak var recipeText: UITextView!
    
    let recipeTextPlaceholder = "Stir with ice, strain into chilled rocks glass."
    
    var added = false
    var recipe: Recipe?
    var editingRecipe = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recipeName.autocapitalizationType = UITextAutocapitalizationType.Words
        
        componentTable!.dataSource = self
        componentTable!.delegate = self
        
        recipeText.delegate = self

        if recipe == nil {
            recipe = Recipe.create("", withRating: 0, withText: "")
            recipeText.text = recipeTextPlaceholder
            recipeText.textColor = UIColor.lightGrayColor()
        } else {
            navigationItem.title = "Edit Recipe"

            recipeName!.text = recipe!.name
            if recipe!.text.isEmpty {
                recipeText!.text = recipeTextPlaceholder
                recipeText.textColor = UIColor.lightGrayColor()
            } else {
                recipeText!.text = recipe!.text
            }
            
            editingRecipe = true
        }
        
        ratingView!.editing = true // this must come before we set the rating value
        ratingView!.rating = Int(recipe!.rating)
        
        resizeComponentsTable()
        componentTable!.editing = true
        
        let scrollPoint = CGPointMake(0, recipeText.frame.origin.y)
        recipeText.setContentOffset(scrollPoint, animated: false)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        resizeComponentsTable()
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
        let height = componentTable.contentSize.height

        componentTableHeight.constant = min(height, 6*(height / CGFloat(recipe!.components.count)))
        componentTable.setNeedsUpdateConstraints()
    }

    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recipe!.sortedComponents.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = componentTable.dequeueReusableCellWithIdentifier("componentCell") as! UITableViewCell
        cell.textLabel!.text = recipe!.sortedComponents[indexPath.row].string
        return cell
    }

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let deleteAction = UITableViewRowAction(style: .Default, title: "Delete") { (action, indexPath) -> Void in
            let component = self.recipe!.sortedComponents[indexPath.row]
            
            self.recipe!.components.removeObject(component)
            CoreDataHelper.delete(component)
            self.componentTable.reloadData()
            self.resizeComponentsTable()
            self.componentTable.scrollToRowAtIndexPath(NSIndexPath(forItem: self.recipe!.sortedComponents.count-1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
            
            for (index, component) in enumerate(self.recipe!.sortedComponents) {
                component.index = Int16(index)
            }

        }
        
        return [ deleteAction ]
    }

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.row < recipe!.sortedComponents.count
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // even if it does nothing this needs to be here if we want to get a delete event
    }
    
    @IBAction func onCancel(sender: UIBarButtonItem) {
        moc.rollback()
        if editingRecipe {
            performSegueWithIdentifier("unwindToRecipe", sender: self)
        } else {
            performSegueWithIdentifier("unwindToRecipes", sender: self)
        }
    }
    
    @IBAction func onDone(sender: UIBarButtonItem) {
        recipe!.name = recipeName!.text
        recipe!.rating = Int16(ratingView!.rating)
        
        if recipeText!.text == recipeTextPlaceholder {
            recipe!.text = ""
        } else {
            recipe!.text = recipeText!.text
        }

        var error: NSError?
        if moc.save(&error) {
            added = true
            NSNotificationCenter.defaultCenter().postNotificationName("recipe.updated", object: self)
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
                
                Component.create(quantity_n, quantity_d: quantity_d, unit: unit, ingredient: vc.ingredient!, recipe: recipe!, index: Int16(recipe!.components.count))
                
                componentTable.reloadData()
                resizeComponentsTable()
                componentTable.scrollToRowAtIndexPath(NSIndexPath(forItem: recipe!.sortedComponents.count-1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
            }
        }
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        NSLog("\(fromIndexPath.row) => \(toIndexPath.row)")

        if fromIndexPath == toIndexPath {
            return
        }
    
        var sortedComponents = recipe!.sortedComponents
        
        if toIndexPath.row < fromIndexPath.row {
            map(sortedComponents[toIndexPath.row..<fromIndexPath.row], { (component) in
                component.index += 1
            })
        } else if fromIndexPath.row < toIndexPath.row {
            map(sortedComponents[fromIndexPath.row+1...toIndexPath.row], { (component) in
                component.index -= 1
            })
        }
        
        sortedComponents[fromIndexPath.row].index = Int16(toIndexPath.row)
    }
}
