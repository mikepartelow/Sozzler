import UIKit
import CoreData

class RecipeTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
    }
    
    let app = UIApplication.shared.delegate as! AppDelegate
    let userSettings: UserSettings

    var exporter: RecipeExporter?

    var frc: NSFetchedResultsController<NSFetchRequestResult>?
    var ingredient: Ingredient?
    var recipeNameFilter: [String]?

    var shouldRefresh = true
    var shouldScroll = true

    var searchEnabled = false
    var searchController: UISearchController?
    var searchText = ""

    required init!(coder aDecoder: NSCoder) {
        userSettings = app.userSettings
        super.init(coder: aDecoder)

        if Recipe.count() == 0 {
            _ = CannedUnitSource().read()
            _ = CannedRecipeSource().read()
            _ = CoreDataHelper.save()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if app.migrated {
            let alert = UIAlertController(title: "Import New Sozzler 1.1 Recipes?", message: "", preferredStyle: .alert)

            let yes = UIAlertAction(title: "Yes", style: .default) { (action: UIAlertAction!) -> Void in

                RecipeImporter(viewController: self).importRecipes(url: NSURL(string: self.app.ONE_POINT_ONE_NEW_RECIPES_URL)!)
            }

            let no = UIAlertAction(title: "No", style: .default) { (action: UIAlertAction!) -> Void in
            }

            alert.addAction(yes)
            alert.addAction(no)

            present(alert, animated: true, completion: nil)
            app.migrated = false
        }

        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(UINib(nibName: "RecipeCell", bundle: nil), forCellReuseIdentifier: "RecipeCell")
        tableView.rowHeight = UITableView.automaticDimension

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

            if (frc?.sections?.count)! > 0 {
                tableView.scrollToRow(at: IndexPath(row: 0, section: 0) as IndexPath, at: UITableView.ScrollPosition.top, animated: false)
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(self.dataReset), name: NSNotification.Name(rawValue: "data.reset"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.dataReset), name: NSNotification.Name(rawValue: "asset.reset"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RecipeTableViewController.recipeUpdated), name: NSNotification.Name(rawValue: "recipe.updated"), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver("data.reset")
        NotificationCenter.default.removeObserver("asset.reset")
        NotificationCenter.default.removeObserver("recipe.updated")
    }

    @objc func dataReset() {
        shouldScroll = true
        ingredient = nil
        searchText = ""
        searchController?.isActive = false
        refresh()
    }

    @objc func recipeUpdated() {
        refresh()
    }

    override func viewWillAppear(_ animated: Bool) {
        if shouldRefresh {
            refresh()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    @IBAction func onSort(_ sender: UIBarButtonItem) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let sortByRating = UIAlertAction(title: "Sort by Rating", style: .default, handler: {
            (alert: UIAlertAction) -> Void in
            self.userSettings.recipeSortOrder = .Rating
            self.shouldScroll = true
            self.refresh()
        })
        
        let sortByName = UIAlertAction(title: "Sort by Name", style: .default, handler: {
            (alert: UIAlertAction) -> Void in
            self.userSettings.recipeSortOrder = .Name
            self.shouldScroll = true
            self.refresh()
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction) -> Void in
        })
        
        sheet.addAction(sortByName)
        sheet.addAction(sortByRating)
        sheet.addAction(cancel)
        
        present(sheet, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "recipeDetails" {
            let rvc = segue.destination as! RecipeViewController
            let index = tableView.indexPathForSelectedRow!

            rvc.recipe = frc!.object(at: index) as? Recipe

            tableView.deselectRow(at: index, animated: false)
        }
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76;
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "recipeDetails", sender: self)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return frc!.sections!.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return frc!.sections![section].numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeCell", for: indexPath as IndexPath) as! RecipeCell
        let recipe = (frc!.object(at: indexPath as IndexPath) as! Recipe)
        cell.populate(recipe: recipe)
        return cell
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if ingredient != nil || searchText != "" || userSettings.recipeSortOrder != .Name {
            return []
        }

        if searchEnabled {
            return [ UITableView.indexSearch ] + frc!.sectionIndexTitles
        } else {
            return frc!.sectionIndexTitles
        }
    }

    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if searchEnabled && userSettings.recipeSortOrder == .Name {
            if index > 0 {
                return frc!.section(forSectionIndexTitle: title, at: index - 1)
            } else {
                let searchBarFrame = searchController!.searchBar.frame
                tableView.scrollRectToVisible(searchBarFrame, animated: false)
                return NSNotFound
            }
        } else {
            return frc!.section(forSectionIndexTitle: title, at: index)
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let recipe = self.frc!.object(at: indexPath as IndexPath) as! Recipe

        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (action, indexPath) -> Void in
            CoreDataHelper.delete(recipe: recipe)

            if let error = CoreDataHelper.save() {
                NSLog("Save Failed!: \(error)")
                assert(false)
                fatalError()
            } else {
                self.refresh()
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "recipe.deleted"), object: self)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "data.reset"), object: self)
            }

            tableView.isEditing = false
        }

        let exportAction = UITableViewRowAction(style: .normal, title: "Export") { (action, indexPath) -> Void in
            self.exporter = RecipeExporter(viewController: self)
            self.exporter!.export(recipes: [recipe])

            tableView.isEditing = false
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
            if (frc?.sections?.count)! > 0 {
                tableView.scrollToRow(at: IndexPath(row: 0, section: 0) as IndexPath, at: UITableView.ScrollPosition.top, animated: false)
            }
        }
    }

    @IBAction func unwindToRecipes(sender: UIStoryboardSegue)
    {
        if let arvc = sender.source as? AddRecipeViewController {
            if arvc.added {
                refresh()
                if let indexPath = self.frc!.indexPath(forObject: arvc.recipe!) {
                    self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableView.ScrollPosition.middle)
                }
            }
        }
    }

    func updateSearchResultsForSearchController(searchController: UISearchController) {
        searchText = searchController.searchBar.text!
        refresh()
    }
 
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateSearchResultsForSearchController(searchController: searchController!)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchText = ""
        refresh()
    }
    
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
    override func motionEnded(_ with: UIEvent.EventSubtype, with event: UIEvent?) {
        if event!.subtype == UIEvent.EventSubtype.motionShake {
            let indexPath: IndexPath

            if userSettings.recipeSortOrder == .Name {
                let randomSection = Int(arc4random_uniform(UInt32(Recipe.count())))
                indexPath = IndexPath(row: 0, section: randomSection)
            } else if userSettings.recipeSortOrder == .Rating {
                let fiveStarSection = 0
                let limit = frc!.sections![fiveStarSection].numberOfObjects
                let randomRow = Int(arc4random_uniform(UInt32(limit)))
                indexPath = IndexPath(row: randomRow, section: fiveStarSection)
            } else {
                indexPath = IndexPath(row: 0, section: 0)
            }

            tableView.selectRow(at: indexPath as IndexPath, animated: false, scrollPosition: UITableView.ScrollPosition.middle)
            performSegue(withIdentifier: "recipeDetails", sender: self)
        }
    }
}
