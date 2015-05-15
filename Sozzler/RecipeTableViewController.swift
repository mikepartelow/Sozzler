import UIKit
import CoreData

class RecipeTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    let userSettings = (UIApplication.sharedApplication().delegate as! AppDelegate).userSettings
    
    var frc: NSFetchedResultsController?
    var ingredient: Ingredient?
    
    var shouldRefresh = true
    
    var searchController: UISearchController?
    
    var searchText = ""
    
    required init!(coder aDecoder: NSCoder!) {
        searchController = UISearchController(searchResultsController: nil)
        super.init(coder: aDecoder)
        
        if Recipe.count() == 0 {
            CannedRecipeSource().splorp()
            CoreDataHelper.save(nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self

        tableView.registerNib(UINib(nibName: "RecipeCell", bundle: nil), forCellReuseIdentifier: "RecipeCell")
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
    }
    
    func dataReset() {
        shouldRefresh = true
    }
    
    override func viewWillAppear(animated: Bool) {
        if shouldRefresh {
            refresh()
        }
    }

    @IBAction func onSort(sender: UIBarButtonItem) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let sortByRating = UIAlertAction(title: "Sort by Rating", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.userSettings.recipeSortOrder = .Rating
            self.refresh()
        })

        let sortByName = UIAlertAction(title: "Sort by Name", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.userSettings.recipeSortOrder = .Name
            self.refresh()
        })

        let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })

        sheet.addAction(sortByName)
        sheet.addAction(sortByRating)        
        sheet.addAction(cancel)

        presentViewController(sheet, animated: true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let navController = segue.destinationViewController as! UINavigationController
        
        if segue.identifier == "recipeDetails" {
            let rvc = navController.topViewController! as! RecipeViewController
            let index = tableView.indexPathForSelectedRow()!
            rvc.recipe = frc!.objectAtIndexPath(index) as? Recipe
            
            tableView.deselectRowAtIndexPath(index, animated: false)
        }
    }

    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 76;
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("recipeDetails", sender: self)
    }
    
    // NSFetchedResultsControllerDelegate
    //
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return frc!.sections!.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return frc!.sections![section].numberOfObjects! // + 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("RecipeCell", forIndexPath: indexPath) as! RecipeCell
        let recipe = (frc!.objectAtIndexPath(indexPath) as! Recipe)
        cell.populate(recipe)
        return cell
    }

    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
        if userSettings.recipeSortOrder == .Name {
            return [ UITableViewIndexSearch ] + frc!.sectionIndexTitles
        } else {
            return []
        }
    }
    
    override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        if userSettings.recipeSortOrder == .Name {
            if index > 0 {
                return frc!.sectionForSectionIndexTitle(title, atIndex: index - 1)
            } else {
                let searchBarFrame = searchController!.searchBar.frame
                tableView.scrollRectToVisible(searchBarFrame, animated: false)
                return NSNotFound
            }
        } else {
            return frc!.sectionForSectionIndexTitle(title, atIndex: index)
        }
    }

    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let deleteAction = UITableViewRowAction(style: .Default, title: "Delete") { (action, indexPath) -> Void in
            let recipe = self.frc!.objectAtIndexPath(indexPath) as! Recipe

            for component in recipe.components.allObjects as! [Component] {
                // FIXME: duplicated effort! will be recalculated in willSave() but if we don't change the Ingredient, willSave() *wont* be called..
                //
                component.ingredient.recipe_count -= 1
                assert(component.ingredient.recipe_count >= 0, "recipe count went negative")
                CoreDataHelper.delete(component)
            }
            CoreDataHelper.delete(recipe)
            
            var error: NSError?
            if CoreDataHelper.save(&error) {
                self.refresh()
            } else {
                // FIXME:
                // alert: could not blah blah
                NSLog("Save Failed!: \(error)")
            }
            
            tableView.editing = false
        }
        
        return [ deleteAction ]
    }

    func refresh() {
        let predicate: NSPredicate?
        if ingredient != nil {
            predicate = NSPredicate(format: "ANY components.ingredient.name == %@", ingredient!.name)
            navigationItem.title = "Recipes with \(ingredient!.name)"
        } else {
            if searchText != "" {
                predicate = NSPredicate(format: "name contains[c] %@", searchController!.searchBar.text)
            } else {
                predicate = nil
            }
            navigationItem.title = "Recipes by \(userSettings.recipeSortOrderName)"
        }
        
        frc = Recipe.fetchedResultsController(predicate: predicate)
        frc!.delegate = self

        // FIXME: nil seems like a bad idea
        frc!.performFetch(nil)

        tableView.reloadData()

        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()

        searchController!.searchBar.searchBarStyle = UISearchBarStyle.Minimal
        searchController!.searchBar.sizeToFit()

        
        shouldRefresh = false
    }
    
    @IBAction func unwindToRecipes(sender: UIStoryboardSegue)
    {
        if let arvc = sender.sourceViewController as? AddRecipeViewController {
            if arvc.added {
                refresh()
            }
        }
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        searchText = searchController.searchBar.text
        refresh()
    }
}
