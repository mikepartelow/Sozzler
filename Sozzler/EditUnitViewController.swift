import UIKit

class EditUnitViewController: UIViewController {

    @IBOutlet weak var unitNameSingular: UITextField!
    @IBOutlet weak var unitNamePlural: UITextField!

    var added = false
    var unit: Unit?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if unit == nil {
            navigationItem.title = "Add Unit"
            unitNameSingular.becomeFirstResponder()
        } else {
            unitNameSingular.text = unit!.name
            unitNamePlural.text = unit!.plural_name
            navigationItem.title = "Edit Unit"
        }
    }
    
    // FIXME: DRY
    func errorAlert(title: String, button: String) {
        var alert = UIAlertController(title: title, message: "", preferredStyle: .Alert)
        let action = UIAlertAction(title: button, style: .Default) { (action: UIAlertAction!) -> Void in }
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }

    @IBAction func onSave(sender: AnyObject) {
        if unit == nil {
            if Unit.find(unitNameSingular.text) != nil {
                self.errorAlert("Unit already exists.", button: "Oops")
            } else {
                unit = Unit.create(unitNameSingular.text, plural_name: unitNamePlural.text)
            }
        } else {
            unit!.name = Unit.fancyName(unitNameSingular.text)
            unit!.plural_name = Unit.fancyName(unitNamePlural.text)
        }
        
        if unit != nil {
            var error: NSError?
            if CoreDataHelper.save(&error) {
                assert(error == nil)
                added = true
                performSegueWithIdentifier("unwindToUnitTable", sender: self)
            } else {
                // FIXME:
                // alert: could not blah blah
                
                NSLog("Save Failed!: \(error)")
            }
        }
    }
}
