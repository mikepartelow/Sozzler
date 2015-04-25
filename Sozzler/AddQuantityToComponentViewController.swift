import UIKit
import CoreData

class AddQuantityToComponentViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var integerPicker: UIPickerView!
    @IBOutlet weak var fractionPicker: UIPickerView!
    @IBOutlet weak var unitPicker: UIPickerView!
    
    let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
    let frc: NSFetchedResultsController
    
    let integers = ["", 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
    let fractions = ["", "⅛", "¼", "½", "¾", "⅓", "⅔"]
    
    required init(coder aDecoder: NSCoder) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        frc = NSFetchedResultsController(fetchRequest: Unit.fetchRequest(), managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        frc.performFetch(nil)
        
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        integerPicker.delegate = self
        integerPicker.dataSource = self
        
        fractionPicker.delegate = self
        fractionPicker.dataSource = self
        
        unitPicker.delegate = self
        unitPicker.dataSource = self
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case integerPicker:
            return integers.count
        case fractionPicker:
            return fractions.count
        case unitPicker:
            return frc.sections![component].numberOfObjects!
        default:
            return 0
        }
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        switch pickerView {
        case integerPicker:
            return "\(integers[row])"
        case fractionPicker:
            return fractions[row]
        case unitPicker:
            let unit = frc.objectAtIndexPath(NSIndexPath(forRow: row, inSection: 0)) as! Unit
            return unit.name
        default:
            return ""
        }
    }

}
