import UIKit
import CoreData

class RecipeTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    let userSettings = (UIApplication.sharedApplication().delegate as! AppDelegate).userSettings
    
    var frc: NSFetchedResultsController?
    var ingredient: Ingredient?
    
    var shouldRefresh = true
    
    var searchEnabled = false
    var searchController: UISearchController?
    var searchText = ""
    
    required init!(coder aDecoder: NSCoder!) {
        super.init(coder: aDecoder)
        
        if Recipe.count() == 0 {
            CannedRecipeSource().read()
            CoreDataHelper.save(nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self

        tableView.registerNib(UINib(nibName: "RecipeCell", bundle: nil), forCellReuseIdentifier: "RecipeCell")
        tableView.rowHeight = UITableViewAutomaticDimension

        searchEnabled = (ingredient == nil)
        
        if searchEnabled {
            definesPresentationContext = true
            refresh()

            searchController = UISearchController(searchResultsController: nil)
            searchController!.searchResultsUpdater = self
            searchController!.searchBar.delegate = self
            searchController!.dimsBackgroundDuringPresentation = false

            tableView.tableHeaderView = searchController!.searchBar
            searchController!.searchBar.sizeToFit()

            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataReset", name: "data.reset", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataImported", name: "data.imported", object: nil)

    }
    
    func dataReset() {
        shouldRefresh = true
    }
    
    func dataImported() {
        refresh()
    }
    
    override func viewWillAppear(animated: Bool) {
        if shouldRefresh {
            refresh()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    @IBAction func onSort(sender: UIBarButtonItem) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let sortByRating = UIAlertAction(title: "Sort by Rating", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.userSettings.recipeSortOrder = .Rating
            self.refresh()
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
        })

        let sortByName = UIAlertAction(title: "Sort by Name", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.userSettings.recipeSortOrder = .Name
            self.refresh()
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
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
            NSLog("index: \(index.row) \(index.section))")

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
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return frc!.sections!.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return frc!.sections![section].numberOfObjects!
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("RecipeCell", forIndexPath: indexPath) as! RecipeCell
        let recipe = (frc!.objectAtIndexPath(indexPath) as! Recipe)
        cell.populate(recipe)
        return cell
    }

    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
        if ingredient != nil || searchText != "" || userSettings.recipeSortOrder != .Name {
            return []
        }
        
        if searchEnabled {
            return [ UITableViewIndexSearch ] + frc!.sectionIndexTitles
        } else {
            return frc!.sectionIndexTitles
        }
    }
    
    override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        if searchEnabled && userSettings.recipeSortOrder == .Name {
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
            NSNotificationCenter.defaultCenter().postNotificationName("recipe.deleted", object: self)

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
                predicate = NSPredicate(format: "(name contains[c] %@) OR (components.ingredient.name contains[c] %@)", searchText, searchText)
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
        
        shouldRefresh = false
    }
    
    @IBAction func unwindToRecipes(sender: UIStoryboardSegue)
    {
        if let arvc = sender.sourceViewController as? AddRecipeViewController {
            if arvc.added {
                refresh()
                let indexPath = self.frc!.indexPathForObject(arvc.recipe!)
                self.tableView.selectRowAtIndexPath(indexPath!, animated: true, scrollPosition: UITableViewScrollPosition.Middle)
            }
        }
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        searchText = searchController.searchBar.text
        refresh()
    }

    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent) {
        if event.subtype == UIEventSubtype.MotionShake {
            let indexPath: NSIndexPath
            
            if userSettings.recipeSortOrder == .Name {
                let randomSection = Int(arc4random_uniform(UInt32(Recipe.count())))
                
                // FIXME: what if no recipes at all?
                indexPath = NSIndexPath(forRow: 0, inSection: randomSection)
            } else if userSettings.recipeSortOrder == .Rating {
                let fiveStarSection = 0
                let limit = frc!.sections![fiveStarSection].numberOfObjects!
                let randomRow = Int(arc4random_uniform(UInt32(limit)))
                
                // FIXME: what if there aren't any five star recipes?
                // FIXME: what if no recipes at all?
                indexPath = NSIndexPath(forRow: randomRow, inSection: fiveStarSection)
            } else {
                // FIXME: what if no recipes at all?
                indexPath = NSIndexPath(forRow: 0, inSection: 0)
            }
            
            tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.Middle)
            performSegueWithIdentifier("recipeDetails", sender: self)
        }
    }
}
