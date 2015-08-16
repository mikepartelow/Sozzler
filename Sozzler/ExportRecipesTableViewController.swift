import UIKit
import CoreData

class ExportRecipesTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    let userSettings = (UIApplication.sharedApplication().delegate as! AppDelegate).userSettings
    
    var exporter: RecipeExporter?
    
    var frc: NSFetchedResultsController?
    var recipeNameFilter: [String]?
    
    var shouldRefresh = true
    var shouldScroll = true
    
    var searchController: UISearchController?
    var searchText = ""
    
    var selectedRecipes = Set<String>(Recipe.all().map({ $0.name }))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.registerNib(UINib(nibName: "RecipeCell", bundle: nil), forCellReuseIdentifier: "RecipeCell")
        tableView.rowHeight = UITableViewAutomaticDimension
        
//        navigationItem.title = "Export"

        definesPresentationContext = true
        refresh()
        
        searchController = UISearchController(searchResultsController: nil)
        searchController!.searchResultsUpdater = self
        searchController!.searchBar.delegate = self
        searchController!.dimsBackgroundDuringPresentation = false
        
        tableView.tableHeaderView = searchController!.searchBar
        searchController!.searchBar.sizeToFit()
        

        let cancel = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "onCancel:")
        let sort = UIBarButtonItem(title: "Sort", style: .Plain, target: self, action: "onSort:")
        
        navigationItem.leftBarButtonItems = [cancel, sort]
        
        let selectAll = UIBarButtonItem(title: "Deselect All", style: .Plain, target: self, action: "onSelectAll:")
        let export = UIBarButtonItem(title: "Export", style: .Plain, target: self, action: "onDone:")
        
        navigationItem.rightBarButtonItems = [export, selectAll]
        
        
        if frc?.sections?.count > 0 {
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
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

    @IBAction func onSelectAll(sender: UIBarButtonItem) {
        if sender.title == "Select All" {
            sender.title = "Deselect All"
            selectedRecipes = Set<String>(Recipe.all().map({ $0.name }))
            refresh()
        } else {
            sender.title = "Select All"
            selectedRecipes.removeAll()
            refresh()
        }
    }

    @IBAction func onDone(sender: UIBarButtonItem) {
        exporter = RecipeExporter(viewController: self)
        exporter!.export(Recipe.all().filter({ self.selectedRecipes.contains($0.name) }),
            completion: { self.performSegueWithIdentifier("unwindToData", sender: self) })
    }

    @IBAction func onCancel(sender: UIBarButtonItem) {
        performSegueWithIdentifier("unwindToData", sender: self)
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
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 76;
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let recipe = (frc!.objectAtIndexPath(indexPath) as! Recipe)

        if selectedRecipes.contains(recipe.name) {
            selectedRecipes.remove(recipe.name)
        } else {
            selectedRecipes.insert(recipe.name)
        }
        
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return frc!.sections!.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return frc!.sections![section].numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("RecipeCell", forIndexPath: indexPath) as! RecipeCell
        let recipe = (frc!.objectAtIndexPath(indexPath) as! Recipe)
        cell.populate(recipe)
        if selectedRecipes.contains(recipe.name) {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        cell.selectionStyle = .None
        return cell
    }
    
    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        if searchText != "" || userSettings.recipeSortOrder != .Name {
            return []
        }
        
        return [ UITableViewIndexSearch ] + frc!.sectionIndexTitles
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
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let recipe = self.frc!.objectAtIndexPath(indexPath) as! Recipe
        
        let deleteAction = UITableViewRowAction(style: .Default, title: "Delete") { (action, indexPath) -> Void in
            CoreDataHelper.delete(recipe)
            
            if let error = CoreDataHelper.save() {
                NSLog("Save Failed!: \(error)")
                assert(false)
                fatalError()
            } else {
                self.refresh()
                NSNotificationCenter.defaultCenter().postNotificationName("recipe.deleted", object: self)
                NSNotificationCenter.defaultCenter().postNotificationName("data.reset", object: self)
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
        if searchText != "" {
            predicate = NSPredicate(format: "(name contains[c] %@) OR (components.ingredient.name contains[c] %@)", searchText, searchText)
        } else {
            predicate = nil
        }
        
        frc = Recipe.fetchedResultsController(predicate)
        frc!.delegate = self
        
        do {
            // FIXME: nil seems like a bad idea
            try frc!.performFetch()
        } catch _ {
        }
        
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
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        searchText = searchController.searchBar.text!
        refresh()
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
}
