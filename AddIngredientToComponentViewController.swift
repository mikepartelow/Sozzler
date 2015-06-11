import UIKit
import CoreData

class AddIngredientToComponentViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    var frc: NSFetchedResultsController?
    var ingredient: Ingredient?
    
    var searchController: UISearchController?
    var searchText = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        
        definesPresentationContext = true
        refresh()
        
        searchController = UISearchController(searchResultsController: nil)
        searchController!.searchResultsUpdater = self
        searchController!.searchBar.delegate = self
        searchController!.dimsBackgroundDuringPresentation = false
        
        tableView.tableHeaderView = searchController!.searchBar
        searchController!.searchBar.sizeToFit()
        
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        ingredient = (frc!.objectAtIndexPath(indexPath) as! Ingredient)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return frc!.sections!.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return frc!.sections![section].numberOfObjects!
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ingredientCell", forIndexPath: indexPath) as! UITableViewCell
        let ingredient = frc!.objectAtIndexPath(indexPath) as! Ingredient
        
        cell.textLabel!.text = ingredient.name
        
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

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "addQuantityToComponent" {
            let nav = segue.destinationViewController as! UINavigationController
            let addQuantityToComponentViewController = nav.topViewController as! AddQuantityToComponentViewController
            let idx = tableView.indexPathForSelectedRow()
            
            addQuantityToComponentViewController.ingredient = (frc!.objectAtIndexPath(idx!) as! Ingredient)
        }
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
                
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
        tableView.reloadData()
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
                // NOTE: unlike in IngredientTableViewController we can't save here because the moc has a partially construted, invalid Recipe
                //
                if ingredient.validateForInsert(&error) {
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

    func updateSearchResultsForSearchController(searchController: UISearchController) {
        searchText = searchController.searchBar.text
        refresh()
    }
    
    @IBAction func unwindToAddIngredientToComponent(sender: UIStoryboardSegue)
    {
    }
}
