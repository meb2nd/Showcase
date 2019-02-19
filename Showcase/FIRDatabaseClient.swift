//
//  FIRDatabaseClient.swift
//  Showcase
//
//  Created by Pete Barnes on 10/18/17.
//  Copyright © 2017 Pete Barnes. All rights reserved.
//  This class based on information found at: https://developer.apple.com/videos/play/wwdc2017/241/
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
    var connectedRef: DatabaseReference!
    var storageRef: StorageReference!
    fileprivate var _refAddHandle: DatabaseHandle!
    fileprivate var _refChangedHandle: DatabaseHandle!
    fileprivate var _connectedRefChangedHandle: DatabaseHandle!
    static let sharedInstance = FIRDatabaseClient()
    var shouldShowConnectionResumeAlert = false
    var shouldShowConnectionFailedAlert = true
    var isWaitingForInitialConnection = true
    fileprivate var intitialConnectionTimer: Timer?
    fileprivate var connectionAlert: UIAlertController?
    
    // MARK:  - Init
    private override init() {}
    
    // MARK: - Configuration Functions
    
    func configureDatabase() {
        ref = Database.database().reference()
        _refAddHandle = ref.child("scripts").observe(.childAdded) { (snapshot: DataSnapshot) in
            
            self.updateContextFromSnapshot(snapshot)
        }
        
        _refChangedHandle = ref.child("scripts").observe(.childChanged) { (snapshot: DataSnapshot) in
            
            self.updateContextFromSnapshot(snapshot)
        }
        
        // Code below based on information from:  https://firebase.google.com/docs/database/ios/offline-capabilities#section-connection-state
        connectedRef = Database.database().reference(withPath: ".info/connected")
        _connectedRefChangedHandle = connectedRef.observe(.value, with: { snapshot in
            
            if snapshot.value as? Bool ?? false {
                print("Connected")
                
                if self.shouldShowConnectionResumeAlert {
                    performUIUpdatesOnMain {
                        
                        if let timer = self.intitialConnectionTimer,
                            timer.isValid {
                            timer.invalidate()
                            self.intitialConnectionTimer = nil
                        }
                        
                        self.shouldShowConnectionResumeAlert = false
                        self.shouldShowConnectionFailedAlert = true
                        
                        // Do not display the alert if this is the initial connection
                        if self.isWaitingForInitialConnection {
                            self.isWaitingForInitialConnection = false
                            return
                        }
                        
                        self.presentAlert(withTitle: "Showcase Connection Status", message: "Connected to Server. Full functionality will resume.")
                    }
                }
                
            } else {
                print("Not connected")
                
                if self.shouldShowConnectionFailedAlert {
                    
                    self.shouldShowConnectionResumeAlert = true
                    self.shouldShowConnectionFailedAlert = false
                    
                    performUIUpdatesOnMain {
                        
                        // Delay alert if we're waiting for initial connection
                        if self.isWaitingForInitialConnection {
                            self.intitialConnectionTimer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(self.waitForInitialConnectionTimedOut), userInfo: nil, repeats: false)
                        } else {
                            self.presentConnectionFailedAlert()
                        }
                    }
                }
            }
        })
    }
    
    func configureStorage() {
        storageRef = Storage.storage().reference()
    }
    
    deinit {
        ref.child("scripts").removeObserver(withHandle: _refAddHandle)
        ref.child("scripts").removeObserver(withHandle: _refChangedHandle)
        ref.child("scripts").removeObserver(withHandle: _connectedRefChangedHandle)
    }
    
    // MARK:  Helper Functions
    
    @objc fileprivate func waitForInitialConnectionTimedOut() {
        
        isWaitingForInitialConnection = false
        intitialConnectionTimer = nil
        presentConnectionFailedAlert()
    }
    
    fileprivate func presentConnectionFailedAlert() {
        presentAlert(withTitle: "Showcase Connection Error", message: "Showcase cannot connect to server. Limited functionality until connection restored.")
    }
    
    
    fileprivate func presentAlert(withTitle title: String, message: String?) {
        
        if let viewController = UIApplication.shared.topMostViewController() {
            
            presentAlert(viewController, title: title, message: message)
        }
    }
    
    fileprivate func presentAlert(_ viewController: UIViewController, title: String, message: String?) {
        
        if connectionAlert != nil {
            connectionAlert?.dismiss(animated: true, completion: nil)
        }
        connectionAlert = UIAlertController()
        connectionAlert?.title = title
        connectionAlert?.message = message
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { action in self.connectionAlert?.dismiss(animated: true, completion: {self.connectionAlert = nil})
        }
        
        // Support display in iPad
        connectionAlert?.popoverPresentationController?.sourceView = viewController.view
        connectionAlert?.popoverPresentationController?.sourceRect = CGRect(x: viewController.view.bounds.size.width / 2.0, y: viewController.view.bounds.size.height / 2.0, width: 1.0, height: 1.0)
        
        connectionAlert?.addAction(okAction)
        viewController.present(connectionAlert!, animated: true, completion: nil)
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
            // We weren't able to parse any of the scripts
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
            let gender = script["gender"],
            let ageGroup = script["ageGroup"],
            let scriptType = script["scriptType"],
            let uid = Auth.auth().currentUser?.uid else {
                // Don't have enough information to construct a Script
                return nil }
        let fetchRequest: NSFetchRequest<Script> = Script.fetchRequest()
        let predicate = NSPredicate(format: "uid = %@ AND url = %@", argumentArray: [uid, pdfURL])
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
                    existingScript.gender = gender
                    existingScript.url = pdfURL
                    existingScript.genre = genre
                    existingScript.title = title
                    existingScript.ageGroup = ageGroup
                    existingScript.scriptType = scriptType
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
            newScript.ageGroup = ageGroup
            newScript.scriptType = scriptType
            newScript.uid = uid
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
    
    func fetchPDF(for script: Script, userName: String, completion: @escaping (PDFResult) -> Void) {
        
        // If we already have the document just return it
        if let document = script.document {
            guard let pdf = PDFDocument(data: document as Data) else {
                // Couldn't create a pdf
                completion(.failure(ScriptError.pdfCreationError))
                return
            }
            completion(.success(pdf))
            return
        }
        
        // Otherwise if we have a valid URL try to download it
        guard let pdfURL = script.url else {
            completion(.failure(ScriptError.invalidPDFURL))
            return
        }
        
        // Download the pdf
        Storage.storage().reference(forURL: pdfURL).getData(maxSize: INT64_MAX) { (data, error) in
            
            guard error == nil else {
                print("Error downloading: \(error as Optional)")
                completion(.failure(error!))
                return
            }
            
            guard let data = data,
                let pdf = PDFDocument(data: data) else {
                    // Couldn't create a pdf
                    completion(.failure(ScriptError.pdfCreationError))
                    return
            }
            
            // Watermark the PDF
            pdf.delegate = self
            self.addWatermark(to: pdf, userName: userName)
            
            // Save the downloaded pdf
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let stack = appDelegate.stack
            
            stack.performBackgroundBatchOperation() { (workerContext) in
                
                let backgroundScript = workerContext.object(with: script.objectID) as! Script
                
                workerContext.performAndWait {
                    backgroundScript.document = pdf.dataRepresentation() as NSData?
                }
                
                self.saveIfNeeded(workerContext)
                completion(.success(pdf))
            }
        }
    }
}

// MARK: - FIRDatabaseClient (PDF Watermark functions)

extension FIRDatabaseClient {
    
    fileprivate func generateWatermark(userName: String) -> String {
        
        var watermark = userName.uppercased()
        
        if watermark.count >= 16 {
            watermark = String(watermark.truncated())
        } else {
            var padding:Int = (15 - watermark.count)/2
            
            while padding > 0 {
                watermark = " " + watermark
                padding -= 1
            }
        }
        
        return watermark
    }
    
    fileprivate func addWatermark(to document: (PDFDocument), userName: String) {
        
        let watermark = generateWatermark(userName: userName)
        
        for index in 0 ... document.pageCount - 1 {
            
            if let page = document.page(at: index) as? WatermarkPage {
                
                page.watermark = watermark as NSString
            }
        }
    }
}

// MARK: - FIRDatabaseClient: PDFDocumentDelegate

extension FIRDatabaseClient: PDFDocumentDelegate {
    func classForPage() -> AnyClass {
        return WatermarkPage.self
    }
}
