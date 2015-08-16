import UIKit
import CoreData

class AddRecipeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UIGestureRecognizerDelegate {
    let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var recipeName: UITextField!
    @IBOutlet weak var componentTable: UITableView!
    @IBOutlet weak var componentTableHeight: NSLayoutConstraint!

    @IBOutlet weak var recipeTextHeight: NSLayoutConstraint!
    @IBOutlet weak var ratingView: RatingView!
    @IBOutlet weak var recipeText: UITextView!
    
    @IBOutlet weak var contentView: UIView!
    
    let recipeTextPlaceholder = "Stir with ice, strain into chilled rocks glass."
    
    var keyboardRect = CGRect()
    
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
        resizeRecipeText()
        
        let scrollPoint = CGPointMake(0, recipeText.frame.origin.y)
        recipeText.setContentOffset(scrollPoint, animated: false)

        // ridiculous hack to avoid "scrolling uitextfield" rotation bug
        //
        recipeName!.layer.borderColor = UIColor.whiteColor().CGColor
        recipeName!.layer.borderWidth = 1.0

//        recipeText.layer.borderColor = UIColor.blackColor().CGColor
//        recipeText.layer.borderWidth = 1.0

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        
        let pan = UIPanGestureRecognizer(target: self, action: "dismissKeyboard")
        pan.cancelsTouchesInView = false
        pan.delegate = self
        scrollView.addGestureRecognizer(pan)
        
        let tap = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        tap.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tap)
        
        recipeName.addTarget(self, action: "dismissKeyboard", forControlEvents: UIControlEvents.EditingDidEndOnExit)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(UIKeyboardWillShowNotification)
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return !recipeName.isFirstResponder() && !recipeText.isFirstResponder()
    }

    func dismissKeyboard() {
        view.endEditing(true)
    }

    func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let r = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue {
                keyboardRect = r
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        resizeComponentsTable()
    }

    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        resizeComponentsTable()
        recipeText.resignFirstResponder()
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        if textView == recipeText {
            if recipeText!.text == recipeTextPlaceholder {
                recipeText!.text = ""
                recipeText!.textColor = UIColor.blackColor()
            }
            
            scrollView.setContentOffset(CGPointMake(0, 0), animated: false)
            
            let contentInsets = UIEdgeInsetsMake(0, 0, keyboardRect.height, 0)
            scrollView.contentInset = contentInsets
            scrollView.scrollIndicatorInsets = contentInsets
            
            let h = view.frame.height - keyboardRect.height
            let nbh = navigationController!.navigationBar.frame.size.height
            let sbh = UIApplication.sharedApplication().statusBarFrame.size.height
            
            let newHeight = h - 8 - nbh - 8 - sbh

            let y = recipeText.frame.origin.y - 8

            scrollView.setContentOffset(CGPointMake(0, y), animated: true)
            recipeTextHeight.constant = newHeight
            recipeText.scrollEnabled = true
        }
    }

    func textViewDidEndEditing(textView: UITextView) {
        if textView == recipeText {
            if recipeText!.text.isEmpty {
                recipeText!.text = recipeTextPlaceholder
                recipeText!.textColor = UIColor.lightGrayColor()
            }

            resizeRecipeText()

            let contentInsets = UIEdgeInsetsMake(0, 0, 0, 0)
            scrollView.contentInset = contentInsets
            scrollView.scrollIndicatorInsets = contentInsets
            
            recipeText.scrollRectToVisible(CGRect(x: 0, y: 0, width: 0, height: 0), animated: true)
            recipeText.scrollEnabled = false
        }
    }
    
    func resizeComponentsTable() {
        componentTableHeight.constant = componentTable.contentSize.height
        componentTable.setNeedsUpdateConstraints()
    }
    
    func resizeRecipeText() {
        let fit = max(176, recipeText.sizeThatFits(recipeText.contentSize).height)
        recipeTextHeight.constant = fit
    }

    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recipe!.sortedComponents.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = componentTable.dequeueReusableCellWithIdentifier("componentCell")!
        cell.textLabel!.text = recipe!.sortedComponents[indexPath.row].string
        return cell
    }

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .Default, title: "Delete") { (action, indexPath) -> Void in
            let component = self.recipe!.sortedComponents[indexPath.row]
            
            self.recipe!.components.removeObject(component)
            CoreDataHelper.delete(component)
            self.componentTable.reloadData()
            self.resizeComponentsTable()
            self.componentTable.scrollToRowAtIndexPath(NSIndexPath(forItem: self.recipe!.sortedComponents.count-1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
            
            for (index, component) in self.recipe!.sortedComponents.enumerate() {
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
        recipe!.name = recipeName!.text!
        recipe!.rating = Int16(ratingView!.rating)
        
        if recipeText!.text == recipeTextPlaceholder {
            recipe!.text = ""
        } else {
            recipe!.text = recipeText!.text
        }

        var error: NSError?
        do {
            try moc.save()
            added = true
            NSNotificationCenter.defaultCenter().postNotificationName("recipe.updated", object: self)
            if editingRecipe {
                performSegueWithIdentifier("unwindToRecipe", sender: self)
            } else {
                performSegueWithIdentifier("unwindToRecipes", sender: self)
            }
        } catch let error1 as NSError {
            error = error1
            NSLog("\(error)")
            let errorMessage = error!.userInfo[NSLocalizedDescriptionKey] as! String
            let errorCode = Recipe.ValidationErrorCode(rawValue: error!.code)
            
            if errorCode == Recipe.ValidationErrorCode.Name {
                recipeName.becomeFirstResponder()
            } else {
                recipeText.resignFirstResponder()
            }
            
            let alert = UIAlertController(title: errorMessage, message: nil, preferredStyle: .Alert)
            let cancelAction = UIAlertAction(title: "OK", style: .Default) { (action: UIAlertAction) -> Void in }
            alert.addAction(cancelAction)
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func unwindToAddRecipe(sender: UIStoryboardSegue)
    {
        if let _ = sender.sourceViewController as? AddIngredientToComponentViewController {
        } else if let vc = sender.sourceViewController as? AddQuantityToComponentViewController {
            if let unit = vc.unit {
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
        if fromIndexPath == toIndexPath {
            return
        }
    
        var sortedComponents = recipe!.sortedComponents
        
        if toIndexPath.row < fromIndexPath.row {
            sortedComponents[toIndexPath.row..<fromIndexPath.row].map({ (component) in
                component.index += 1
            })
        } else if fromIndexPath.row < toIndexPath.row {
            sortedComponents[fromIndexPath.row+1...toIndexPath.row].map({ (component) in
                component.index -= 1
            })
        }
        
        sortedComponents[fromIndexPath.row].index = Int16(toIndexPath.row)
    }
}
