import UIKit
import CoreData

// http://stackoverflow.com/questions/2809192/core-data-fetchedresultscontroller-question-what-is-sections-for

class IngredientTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    let userSettings = (UIApplication.sharedApplication().delegate as! AppDelegate).userSettings

    var frc: NSFetchedResultsController?
    
    var shouldRefresh = true
    
    var searchController: UISearchController?
    var searchText = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self

        tableView.rowHeight = UITableViewAutomaticDimension

        definesPresentationContext = true
        refresh()
        
        searchController = UISearchController(searchResultsController: nil)
        searchController!.searchResultsUpdater = self
        searchController!.searchBar.delegate = self
        searchController!.dimsBackgroundDuringPresentation = false
        
        tableView.tableHeaderView = searchController!.searchBar
        searchController!.searchBar.sizeToFit()
        
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataReset", name: "data.reset", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataReset", name: "recipe.deleted", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataReset", name: "recipe.updated", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver("data.reset")
        NSNotificationCenter.defaultCenter().removeObserver("recipe.deleted")
        NSNotificationCenter.defaultCenter().removeObserver("recipe.updated")
    }

    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 56;
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
                let ingredient = Ingredient.create(ingredientName)
                
                var error: NSError?
                if CoreDataHelper.save(&error) {
                    self.refresh()
                    let indexPath = self.frc!.indexPathForObject(ingredient)
                    self.tableView.selectRowAtIndexPath(indexPath!, animated: true, scrollPosition: UITableViewScrollPosition.Middle)
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
            textField.autocapitalizationType = UITextAutocapitalizationType.Words
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
                    assert(error == nil)
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let navController = segue.destinationViewController as! UINavigationController
        let rtvc = navController.topViewController! as! RecipeTableViewController
        
        let index = tableView.indexPathForSelectedRow()!
        rtvc.ingredient = frc!.objectAtIndexPath(index) as? Ingredient
        tableView.deselectRowAtIndexPath(index, animated: false)
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
        if searchText != "" {
            return []
        } else {
            return [ UITableViewIndexSearch ] + frc!.sectionIndexTitles
        }
    }
    
    override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        if index > 0 {
            return frc!.sectionForSectionIndexTitle(title, atIndex: index - 1)
        } else {
            let searchBarFrame = searchController!.searchBar.frame
            tableView.scrollRectToVisible(searchBarFrame, animated: false)
            return NSNotFound
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CGFloat(52)
    }
    
    // FIXME: DRY
    func refresh() {
        let predicate: NSPredicate?
        if searchText != "" {
            predicate = NSPredicate(format: "name contains[c] %@", searchText)
        } else {
            predicate = nil
        }
        frc = Ingredient.fetchedResultsController(predicate: predicate)
        
        frc!.delegate = self
        
        // FIXME: nil seems like a bad idea
        frc!.performFetch(nil)
        
        navigationItem.title = "Ingredients"
        
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
        tableView.reloadData()
        
        shouldRefresh = false
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        searchText = searchController.searchBar.text
        refresh()
    }
}
