//
//  FIRDatabaseClient.swift
//  Showcase
//
//  Created by Pete Barnes on 10/18/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//

import Foundation
import Firebase
import CoreData
import PDFKit

// MARK: - Enums

enum PDFResult {
    case success(PDFDocument)
    case downloading
    case failure(Error)
}

enum ScriptError: Error {
    case pdfCreationError
    case pdfDownloadError
    case invalidPDFURL
}

enum ScriptsResult {
    case success([Script])
    case failure(Error)
}

// MARK: Properties

class FIRDatabaseClient: NSObject {
    
    var ref: DatabaseReference!
    var storageRef: StorageReference!
    fileprivate var _refAddHandle: DatabaseHandle!
    fileprivate var _refChangedHandle: DatabaseHandle!
    static let sharedInstance = FIRDatabaseClient()
    
    private override init() {}
    
    
    func configureDatabase() {
        ref = Database.database().reference()
        _refAddHandle = ref.child("scripts").observe(.childAdded) { (snapshot: DataSnapshot) in
            
            self.updateContextFromSnapshot(snapshot)
        }
        
        _refChangedHandle = ref.child("scripts").observe(.childChanged) { (snapshot: DataSnapshot) in
            
            self.updateContextFromSnapshot(snapshot)
        }
    }
    
    func configureStorage() {
        storageRef = Storage.storage().reference()
    }
    
    deinit {
        ref.child("scripts").removeObserver(withHandle: _refAddHandle)
        ref.child("scripts").removeObserver(withHandle: _refChangedHandle)
    }
}

// MARK: - FIRDatabaseClient (Core Data)

extension FIRDatabaseClient {
    
    fileprivate func saveIfNeeded(_ context: NSManagedObjectContext) {
        context.perform {
            do {
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                let saveError = error as NSError
                print("Unable to Save Script")
                print("\(saveError), \(saveError.localizedDescription)")
            }
        }
    }
    
    private func scripts(fromSnapshotsArray snapshotsArray: [DataSnapshot], into context: NSManagedObjectContext) -> ScriptsResult {
        
        var finalScripts = [Script]()
        
        for snapshot in snapshotsArray {
            if let script = script(fromSnapshot: snapshot, into: context){
                finalScripts.append(script)
            }
        }
        
        if finalScripts.isEmpty && !snapshotsArray.isEmpty {
            // We weren't able to parse any of the photos
            // Maybe the JSON format for scripts has changed
            return .failure(APIError.jsonMappingError(converstionError: .custom("Could not parse any of the scripts.")))
        }
        
        return .success(finalScripts)
    }
    
    private func script(fromSnapshot snapshot: DataSnapshot,
                        into context: NSManagedObjectContext) -> Script? {
        guard
            let script = snapshot.value as? [String: String],
            let pdfURL = script["pdfURL"],
            let title = script["title"],
            let dateCreated = script["dateCreated"],
            let dateModified = script["dateModified"],
            let genre = script["genre"],
            let gender = script["gender"] else {
                // Don't have enough information to construct a Photo
                return nil }
        let fetchRequest: NSFetchRequest<Script> = Script.fetchRequest()
        let predicate = NSPredicate(format: "url = %@", argumentArray: [pdfURL])
        fetchRequest.predicate = predicate
        var fetchedScripts: [Script]?
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm:ss"
        
        context.performAndWait {
            fetchedScripts = try? fetchRequest.execute()
        }
        if let existingScript = fetchedScripts?.first {
            
            if let modifiedDate = dateFormatter.date(from: dateModified),
                !existingScript.dateModified!.isEqual(to: modifiedDate) {
                context.performAndWait {
                    existingScript.dateModified = modifiedDate as NSDate
                    existingScript.document = nil
                }
            }
            
            saveIfNeeded(context)
            return existingScript
        }
        
        var newScript: Script!
        
        context.performAndWait {
            newScript = Script(context: context)
            newScript.gender = gender
            newScript.url = pdfURL
            newScript.genre = genre
            newScript.title = title
            newScript.dateCreated = (dateFormatter.date(from: dateCreated) ?? Date()) as NSDate
            newScript.dateModified = (dateFormatter.date(from: dateModified) ?? Date()) as NSDate
        }
        
        saveIfNeeded(context)
        return newScript
    }
    
    fileprivate func updateContextFromSnapshot(_ snapshot: (DataSnapshot)) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let stack = appDelegate.stack
        
        stack.performBackgroundBatchOperation() { (workerContext) in
            
            _ = self.script(fromSnapshot: snapshot, into: workerContext)
        }
    }
    
    func fetchPDF(for script: Script, context: NSManagedObjectContext) -> PDFResult {
        
        // If we already have the document just return it
        if let document = script.document {
            guard let pdf = PDFDocument(data: document as Data) else {
                // Couldn't create an pdf
                return .failure(ScriptError.pdfCreationError)
            }
            return .success(pdf)
        }
        
        // Otherwise if we have a valid URL try to download it
        guard let pdfURL = script.url else {
            return .failure(ScriptError.invalidPDFURL)
        }
        
        // Download the pdf
        Storage.storage().reference(forURL: pdfURL).getData(maxSize: INT64_MAX) { (data, error) in
            
            guard error == nil else {
                print("Error downloading: \(error as Optional)")
                return
            }
            
            // Save the downloaded pdf
            context.performAndWait {
                script.document = data as NSData?
            }
            
            self.saveIfNeeded(context)
        }
        
        return .downloading
    }
}

