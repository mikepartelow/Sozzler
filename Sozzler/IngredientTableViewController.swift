import UIKit
import CoreData

// http://stackoverflow.com/questions/2809192/core-data-fetchedresultscontroller-question-what-is-sections-for

class IngredientTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    let userSettings = (UIApplication.sharedApplication().delegate as! AppDelegate).userSettings

    var frc: NSFetchedResultsController?
    
    var shouldRefresh = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataReset", name: "data.reset", object: nil)
    }
    
    func dataReset() {
        shouldRefresh = true
    }

    override func viewWillAppear(animated: Bool) {
        if shouldRefresh {
            refresh()
        }
    }
    
    func errorAlert(title: String, button: String) {
        var alert = UIAlertController(title: title, message: "", preferredStyle: .Alert)
        let action = UIAlertAction(title: button, style: .Default) { (action: UIAlertAction!) -> Void in }
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }

    @IBAction func onAdd(sender: UIBarButtonItem) {
        var alert = UIAlertController(title: "Add Ingredient", message: "", preferredStyle: .Alert)
        
        let addAction = UIAlertAction(title: "Add", style: .Default) { (action: UIAlertAction!) -> Void in
            let textField = alert.textFields![0] as! UITextField
            let ingredientName = textField.text
            
            if let ingredient = Ingredient.find(ingredientName) {
                self.errorAlert("Ingredient already exists.", button: "Oops")
            } else {
                Ingredient.create(ingredientName)
                
                var error: NSError?
                if CoreDataHelper.save(&error) {
                    self.refresh()
                } else {
                    // FIXME:
                    // alert: could not blah blah
                    NSLog("Save Failed!: \(error)")
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Default) { (action: UIAlertAction!) -> Void in
        }
        
        alert.addTextFieldWithConfigurationHandler { (textField: UITextField!) -> Void in
            textField.placeholder = "Disgusting Artichoke"
        }
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let deleteAction = UITableViewRowAction(style: .Default, title: "Delete") { (action, indexPath) -> Void in
            let ingredient = self.frc!.objectAtIndexPath(indexPath) as! Ingredient

            if ingredient.recipe_count > 0 {
                self.errorAlert("Ingredient is used by a recipe", button: "OK")
            } else {
                CoreDataHelper.delete(ingredient)
            
                var error: NSError?
                if CoreDataHelper.save(&error) {
                    self.refresh()
                } else {
                    // FIXME:
                    // alert: could not blah blah
                    NSLog("Delete Failed!: \(error)")
                }
            }
            
            tableView.editing = false
        }
        
        return [ deleteAction ]
    }
    
    @IBAction func onSort(sender: UIBarButtonItem) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let sortByName = UIAlertAction(title: "Sort by Name", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.userSettings.ingredientSortOrder = .Name
            self.refresh()
        })
        
        let sortByNumberOfIngredients = UIAlertAction(title: "Sort by Number of Recipes", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.userSettings.ingredientSortOrder = .NumberOfRecipes
            self.refresh()
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })
        
        sheet.addAction(sortByName)
        sheet.addAction(sortByNumberOfIngredients)
        sheet.addAction(cancel)
        
        presentViewController(sheet, animated: true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let navController = segue.destinationViewController as! UINavigationController
        let rtvc = navController.topViewController! as! RecipeTableViewController
        
        let index = tableView.indexPathForSelectedRow()!
        rtvc.ingredient = frc!.objectAtIndexPath(index) as? Ingredient
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return frc!.sections!.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return frc!.sections![section].numberOfObjects!
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("IngredientCell", forIndexPath: indexPath) as! UITableViewCell
        let ingredient = frc!.objectAtIndexPath(indexPath) as! Ingredient
        
        cell.textLabel!.text = ingredient.name
        
        let plural = ingredient.recipe_count > 1 ? "s" : ""
        cell.detailTextLabel!.text = "\(ingredient.recipe_count) recipe\(plural)"
        
        return cell
    }
    
    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
        
        switch userSettings.ingredientSortOrder {
            case .Name:
                return frc!.sectionIndexTitles
            default:
                return []
        }
    }
    
    override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return frc!.sectionForSectionIndexTitle(title, atIndex: index)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CGFloat(52)
    }
    
    // FIXME: DRY
    func refresh() {
        // FIXME: progress indicator is needed especially during onSort()
        //        modal grey translucent alert with swriy : howto?
        frc = Ingredient.fetchedResultsController()
        
        frc!.delegate = self
        
        // FIXME: nil seems like a bad idea
        frc!.performFetch(nil)
        
        navigationItem.title = "Ingredients by \(userSettings.ingredientSortOrderName)"
        
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
        tableView.reloadData()
        
        shouldRefresh = false
    }
}
