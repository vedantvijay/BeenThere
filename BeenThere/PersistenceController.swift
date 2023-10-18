//
//  PersistenceController.swift
//  BeenThere
//
//  Created by Jared Jones on 10/18/23.
//

import Foundation
import CoreData
import CloudKit

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "BeenThere") // Update the data model name here

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Default location for persistent store
            let storeURL = NSPersistentCloudKitContainer.defaultDirectoryURL().appendingPathComponent("BeenThere.sqlite") // Update the SQLite file name here
            let storeDescription = NSPersistentStoreDescription(url: storeURL)

            // Enable CloudKit synchronization
            storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.me.jareddanieljones.beenthere")
            
            // Enable lightweight migration
            storeDescription.shouldMigrateStoreAutomatically = true
            storeDescription.shouldInferMappingModelAutomatically = true
            
            container.persistentStoreDescriptions = [storeDescription]
        }

        container.viewContext.automaticallyMergesChangesFromParent = true

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteChange),
            name: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator
        )
    }
}

extension PersistenceController {
    @objc func handleRemoteChange(_ notification: Notification) {
        // Refresh your data here
        DispatchQueue.main.async {
            // Your code to update UI or refresh data
        }
    }
    
    // Fetch entities
    func fetchLocations(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, fetchLimit: Int? = nil) -> [Location] {
        let request: NSFetchRequest<Location> = Location.fetchRequest()  // Use the typed fetch request for Location
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        if let fetchLimit = fetchLimit {
            request.fetchLimit = fetchLimit
        }
        do {
            let result = try container.viewContext.fetch(request)
            return result
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }


    // Save changes
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let error = error as NSError
                fatalError("Unresolved error: \(error), \(error.userInfo)")
            }
        }
    }
    
    func deleteCloudData(completion: @escaping (Error?) -> Void) {
        let container = CKContainer(identifier: "iCloud.me.jareddanieljones.beenthere")
        let privateDatabase = container.privateCloudDatabase

        let query = CKQuery(recordType: "CD_Location", predicate: NSPredicate(value: true))

        // Updated fetch method without resultsLimit
        privateDatabase.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil) { result in
            switch result {
            case .success(let data):
                let recordIDs = data.matchResults.map { $0.0 } // Extracting CKRecord.ID from the tuple
                let deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)
                
                // Updated completion block for delete operation
                deleteOperation.modifyRecordsResultBlock = { error in
                    completion(error as? Error)
                }
                privateDatabase.add(deleteOperation)

            case .failure(let error):
                completion(error)
            }
        }
    }
}
