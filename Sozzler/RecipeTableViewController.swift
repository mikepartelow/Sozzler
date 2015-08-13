import UIKit
import CoreData

class RecipeTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    let app = UIApplication.sharedApplication().delegate as! AppDelegate
    let userSettings: UserSettings
    
    var exporter: RecipeExporter?
    
    var frc: NSFetchedResultsController?
    var ingredient: Ingredient?
    var recipeNameFilter: [String]?
    
    var shouldRefresh = true
    var shouldScroll = true
    
    var searchEnabled = false
    var searchController: UISearchController?
    var searchText = ""
    
    required init!(coder aDecoder: NSCoder!) {
        userSettings = app.userSettings
        super.init(coder: aDecoder)
        
        if Recipe.count() == 0 {
            CannedUnitSource().read()
            CannedRecipeSource().read()
            CoreDataHelper.save(nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if app.migrated {
            let alert = UIAlertController(title: "Import New Sozzler 1.1 Recipes?", message: "", preferredStyle: .Alert)
            
            let yes = UIAlertAction(title: "Yes", style: .Default) { (action: UIAlertAction!) -> Void in
                
                RecipeImporter(viewController: self).importRecipes(NSURL(string: self.app.ONE_POINT_ONE_NEW_RECIPES_URL)!)
            }
            
            let no = UIAlertAction(title: "No", style: .Default) { (action: UIAlertAction!) -> Void in
            }
            
            alert.addAction(yes)
            alert.addAction(no)
            
            presentViewController(alert, animated: true, completion: nil)
            app.migrated = false
        }
        
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

            if frc?.sections?.count > 0 {
                tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataReset", name: "data.reset", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataReset", name: "asset.reset", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "recipeUpdated", name: "recipe.updated", object: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver("data.reset")
        NSNotificationCenter.defaultCenter().removeObserver("asset.reset")
        NSNotificationCenter.defaultCenter().removeObserver("recipe.updated")
    }
    
    func dataReset() {
        shouldScroll = true
        ingredient = nil
        searchText = ""
        searchController?.active = false
        refresh()
    }

    func recipeUpdated() {
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
            self.shouldScroll = true
            self.refresh()
        })

        let sortByName = UIAlertAction(title: "Sort by Name", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.userSettings.recipeSortOrder = .Name
            self.shouldScroll = true
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
        let recipe = self.frc!.objectAtIndexPath(indexPath) as! Recipe

        let deleteAction = UITableViewRowAction(style: .Default, title: "Delete") { (action, indexPath) -> Void in
            CoreDataHelper.delete(recipe)

            var error: NSError?
            if CoreDataHelper.save(&error) {
                assert(error == nil)                
                self.refresh()
                NSNotificationCenter.defaultCenter().postNotificationName("recipe.deleted", object: self)
                NSNotificationCenter.defaultCenter().postNotificationName("data.reset", object: self)
            } else {
                // FIXME:
                // alert: could not blah blah
                NSLog("Save Failed!: \(error)")
            }
            
            tableView.editing = false
        }
        
        let exportAction = UITableViewRowAction(style: .Normal, title: "Export") { (action, indexPath) -> Void in
            self.exporter = RecipeExporter(viewController: self)
            self.exporter!.export([recipe])
            
            tableView.editing = false
        }
        
        return [ deleteAction, exportAction ]
    }

    func refresh() {
        let predicate: NSPredicate?
        if ingredient != nil {
            predicate = NSPredicate(format: "ANY components.ingredient.name == %@", ingredient!.name)
            navigationItem.title = "Recipes with \(ingredient!.name)"
        } else {
            if searchText != "" {
                predicate = NSPredicate(format: "(name contains[c] %@) OR (components.ingredient.name contains[c] %@)", searchText, searchText)
            } else if recipeNameFilter != nil {
                predicate = NSPredicate(format: "name IN %@", recipeNameFilter!)
                navigationItem.title = "Recipes Imported" // FIXME: breaks generalization
            } else {
                predicate = nil
                navigationItem.title = "Recipes by \(userSettings.recipeSortOrderName)"
            }
        }
        
        frc = Recipe.fetchedResultsController(predicate: predicate)
        frc!.delegate = self

        // FIXME: nil seems like a bad idea
        frc!.performFetch(nil)

        tableView.reloadData()

        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()

        shouldRefresh = false
        if shouldScroll {
            shouldScroll = false
            if frc?.sections?.count > 0 {
                tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
            }
        }
    }
    
    @IBAction func unwindToRecipes(sender: UIStoryboardSegue)
    {
        if let arvc = sender.sourceViewController as? AddRecipeViewController {
            if arvc.added {
                refresh()
                if let indexPath = self.frc!.indexPathForObject(arvc.recipe!) {
                    self.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.Middle)
                }
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
                indexPath = NSIndexPath(forRow: 0, inSection: randomSection)
            } else if userSettings.recipeSortOrder == .Rating {
                let fiveStarSection = 0
                let limit = frc!.sections![fiveStarSection].numberOfObjects!
                let randomRow = Int(arc4random_uniform(UInt32(limit)))
                indexPath = NSIndexPath(forRow: randomRow, inSection: fiveStarSection)
            } else {
                indexPath = NSIndexPath(forRow: 0, inSection: 0)
            }
            
            tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.Middle)
            performSegueWithIdentifier("recipeDetails", sender: self)
        }
    }
}
