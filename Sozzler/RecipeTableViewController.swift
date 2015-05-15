import UIKit
import CoreData

class RecipeTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchBarDelegate {
    let userSettings = (UIApplication.sharedApplication().delegate as! AppDelegate).userSettings
    
    var frc: NSFetchedResultsController?
    var ingredient: Ingredient?
    
    var shouldRefresh = true
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    required init!(coder aDecoder: NSCoder!) {
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
        
        searchBar.delegate = self

        
        // FIXME: use this to add the Sort button when we're root view controller, but not when we're coming from IngredientTable
        //        IngredientTable should display Back

        //        navigationItem.leftBarButtonItem =

        tableView.registerNib(UINib(nibName: "RecipeCell", bundle: nil), forCellReuseIdentifier: "RecipeCell")
        tableView.rowHeight = UITableViewAutomaticDimension
        
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

        let sortByNumberOfIngredients = UIAlertAction(title: "Sort by Number of Ingredients", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.userSettings.recipeSortOrder = .NumberOfIngredients
            self.refresh()
        })

        let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })

        sheet.addAction(sortByName)
        sheet.addAction(sortByRating)        
        sheet.addAction(sortByNumberOfIngredients)
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
        return 88;
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
        return frc!.sections![section].numberOfObjects! + 1
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
            return [ UITableViewIndexSearch ]
        }
    }
    
    override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return frc!.sectionForSectionIndexTitle(title, atIndex: index)
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

    //
    // NSFetchedResultsControllerDelegate

    // FIXME: DRY
    func refresh() {
        // FIXME: progress indicator is needed especially during onSort()
        //        modal grey translucent alert with swriy : howto?

        let predicate: NSPredicate?
        if ingredient != nil {
            predicate = NSPredicate(format: "ANY components.ingredient.name == %@", ingredient!.name)
            navigationItem.title = "Recipes with \(ingredient!.name)"
        } else {
            if searchBar!.text != "" {
                predicate = NSPredicate(format: "name contains[c] %@", searchBar!.text)
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
            }
        }
    }

//    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
//        searchActive = true;
//    }
//    
//    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
//        searchActive = false;
//    }
//    
//    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
//        searchActive = false;
//    }
//    
//    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
//        searchActive = false;
//    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        NSLog("filter: \(searchText)")
        refresh()
    }

//    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String!) -> Bool {
//        // do the filter
////        http://useyourloaf.com/blog/2015/02/16/updating-to-the-ios-8-search-controller.html
////        http://www.raywenderlich.com/76519/add-table-view-search-swift
//        // http://shrikar.com/swift-ios-tutorial-uisearchbar-and-uisearchbardelegate/
//        
//        return true
    // 
//    }
}
