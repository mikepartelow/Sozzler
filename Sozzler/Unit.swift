import CoreData

@objc(Unit)
class Unit: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var plural_name: String

    @NSManaged var recipe_count: Int16
    @NSManaged var index: Int16
    @NSManaged var components: NSSet
    
    class func fancyName(name: String) -> String {
        return name.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
    
    class func all() -> [Unit] {
        return CoreDataHelper.all("Unit", predicate: nil) as! [Unit]
    }
    
    class func fetchedResultsController() -> NSFetchedResultsController {
        let fetchRequest = NSFetchRequest(entityName: "Unit")

        let sortByIndex = NSSortDescriptor(key: "index", ascending: true)
        
        fetchRequest.sortDescriptors = [sortByIndex]
        
        return CoreDataHelper.fetchedResultsController(fetchRequest)
    }

    class func find(name: String) -> Unit? {
        let predicate = NSPredicate(format: "name == %@", Unit.fancyName(name))
        return CoreDataHelper.find("Unit", predicate: predicate) as! Unit?
    }
    
    class func create(name: String, plural_name: String, index: Int = Unit.count()) -> Unit {
        return CoreDataHelper.create("Unit", initializer: {
            (entity, context) -> NSManagedObject in
                let unit = Unit(entity: entity, insertIntoManagedObjectContext: context)

                unit.name = Unit.fancyName(name)
                unit.plural_name = Unit.fancyName(plural_name)
                unit.index = Int16(index)
                unit.recipe_count = 0
                return unit
            }
        ) as! Unit
    }
    
    class func findOrCreate(name: String, plural_name: String) -> Unit {
        let fancyName = Unit.fancyName(name)

        if let unit = Unit.find(fancyName) {
            return unit
        } else {
            return Unit.create(fancyName, plural_name: plural_name)
        }
    }
    
    class func count() -> Int {
        return CoreDataHelper.count("Unit", predicate: nil)
    }

    override func willSave() {
        if !deleted {
            var recipeCounts: [Recipe:Int] = [:]
            
            setPrimitiveValue(Unit.fancyName(name), forKey: "name")
            
            if plural_name.isEmpty {
                setPrimitiveValue(name, forKey: "plural_name")
            }

            for component in components.allObjects as! [Component] {
                if recipeCounts[component.recipe] == nil {
                    recipeCounts[component.recipe] = 1
                } else {
                    recipeCounts[component.recipe]! += 1
                }
            }
            
            let count = recipeCounts.values.count
            setPrimitiveValue(count, forKey: "recipe_count")
        }
    }    
}
