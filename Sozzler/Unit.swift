import CoreData

@objc(Unit)
class Unit: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var recipe_count: Int16
    @NSManaged var index: Int16
    @NSManaged var components: NSSet
    
    class func fancyName(name: String) -> String {
        return name.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
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
    
    class func create(name: String, index: Int = Unit.count()) -> Unit {
        return CoreDataHelper.create("Unit", initializer: {
            (entity, context) -> NSManagedObject in
                let unit = Unit(entity: entity, insertIntoManagedObjectContext: context)
                unit.name = Unit.fancyName(name)
                unit.index = Int16(index)
                unit.recipe_count = 0
                return unit
            }
        ) as! Unit
    }
    
    class func findOrCreate(name: String) -> Unit {
        let fancyName = Unit.fancyName(name)

        if let unit = Unit.find(fancyName) {
            return unit
        } else {
            return Unit.create(fancyName)
        }
    }
    
    class func count() -> Int {
        return CoreDataHelper.count("Unit", predicate: nil)
    }

    override func willSave() {
        if !deleted {
            var recipeCounts: [Recipe:Int] = [:]
            
            setPrimitiveValue(Unit.fancyName(name), forKey: "name")

            for component in components.allObjects as! [Component] {
                if recipeCounts[component.recipe] == nil {
                    recipeCounts[component.recipe] = 1
                } else {
                    recipeCounts[component.recipe]! += 1
                }
            }
            
            let count = recipeCounts.values.array.reduce(0, combine: +)
            setPrimitiveValue(count, forKey: "recipe_count")
        }
    }
    
}
