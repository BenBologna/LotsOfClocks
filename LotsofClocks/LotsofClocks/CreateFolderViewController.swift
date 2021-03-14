//
//  CreateFolderViewController.swift
//  LotsofClocks
//
//  Created by Ben Malaga on 1/18/21.
//

import UIKit
import CoreData

class CreateFolderViewController: UIViewController {

    // MARK:- Variables
    
    // Text field for folder name
    @IBOutlet weak var folderNameTextField: UITextField!
    
    @IBOutlet weak var navBar: UINavigationItem!
    
    @IBOutlet weak var deleteFolderLabel: UILabel!
    
    @IBOutlet weak var deleteFolderControl: UISegmentedControl!
    
    @IBOutlet weak var folderSegmentedControl: UISegmentedControl!
    

    
    // The folder object being saved into the database
    var folder:NSManagedObject? = NSManagedObject()
    
    var folders:[NSManagedObject] = []
    
    var editedFolder:NSManagedObject? = NSManagedObject()
    
    var folderName:String = ""
    
    // isDuplicate raised if folder is a duplicate
    var isDuplicate:Bool = false
    
    var editingFolderID:Int = 0
    
    var isEditOn:Bool = false
    
    var isDeleteOn:Bool = false
    
    // MARK:- View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(isEditOn)
        
        if isEditOn
        {
            navBar.title = "Edit Folder"
            deleteFolderLabel.isHidden = false
            deleteFolderControl.isHidden = false
        }
        else
        {
            navBar.title = "Create Folder"
            deleteFolderLabel.isHidden = true
            deleteFolderControl.isHidden = true
        }

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        isDeleteOn = false
        isDuplicate = false
    }
    
    
    // MARK:- IBActions
    
    // If cancel is pressed, go back to folder screen
    @IBAction func cancelPressed(_ sender: Any)
    {
        dismiss(animated:true, completion: nil)
    }
    
    // If save is pressed, save the folder name, and create a new object in the database
    @IBAction func savePressed(_ sender: Any)
    {
        let name:String = folderNameTextField.text!
        
        if name.count == 0
        {
            folderName = "Folder"
        }
        else
        {
            folderName = name
        }
        
        // If the alarm name is too big, it will shorten it, and if the alarm name is blank, it will default to "Alarm".
        self.save(name: folderName)
        
    }
    

    @IBAction func deleteSwitchActivated(_ sender: UISegmentedControl)
    {
        
        if folderSegmentedControl.selectedSegmentIndex == 0
        {
            isDeleteOn = true
            print("on")
        }
        else
        {
            isDeleteOn = false
            print("off")
        }
    }
    
    
    // If return is pressed on the keyboard, minimize the keyboard
    @IBAction func returnPressed(_ sender: UITextField)
    {
        sender.resignFirstResponder()
    }
    
    
    // MARK: - General Functions
    
    // Saves the object being made into the database
    func save(name: String)
    {
        
        // CoreData set up
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate
        else{return}
      
        let managedContext = appDelegate.persistentContainer.viewContext
        
        
        // Fetches the entity that the object will be saved in, in this case its the Folder entity
        let entity = NSEntityDescription.entity(forEntityName: "Folder", in: managedContext)!
      
        // A fetch request for all Folder entities, compared to the folder being created to ensure no duplication
        let foldersFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Folder")
        
        do
        {
            // Array of all folder entities
            folders = try managedContext.fetch(foldersFetchRequest)
            
            // Iterates through all folders and compares them to the one being made to ensure no duplication
            for object in folders
            {
                if object.value(forKey: "name") as? String == name
                {
                    isDuplicate = true
                }
                
                // If edit mode is on, it will find the folder that is current being edited on, and store it into a variable
                if isEditOn
                {
                    if object.value(forKey: "folderID") as? Int == editingFolderID
                    {
                        editedFolder = object
                    }
                }
            
            }
            
            // If edit is on, it will first check if the delete option was pressed, and if not, it will rename the folder.
            if isEditOn
            {
                if isDeleteOn
                {
                    // Fetches all entities with the entity name of Folder
                    let alarmsFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Alarm")
                    
                    do
                    {
                        let alarmsCopy = try managedContext.fetch(alarmsFetchRequest)
                                    
                        // Deletes all alarms ascociated with the folder being deleted, as well as the folder
                        for object in alarmsCopy
                        {
                            if object.value(forKey:"folderID") as! Int == editingFolderID
                            {
                                    // Removes the alarm from the notification queue if it was scheduled
                                    if object.value(forKey:"notificationID") as! String != ""
                                    {
                                        let center = UNUserNotificationCenter.current()
                                        center.removePendingNotificationRequests(withIdentifiers: [object.value(forKey:"notificationID") as! String])
                                    }
                                    managedContext.delete(object)
                            }
                        }
                                    
                        // Deletes all remainng references to the alarm, and saves the context
                        managedContext.delete(editedFolder!)
                        folders.remove(at: folders.firstIndex(of: editedFolder!)!)
                        appDelegate.saveContext()
                                    

                        }
                        catch let error as NSError
                        {
                            print("Could not fetch. \(error), \(error.userInfo)")
                        }
                }
                
                // Sets the new folders name in replacement to the old ones name
                editedFolder!.setValue(name, forKeyPath: "name")
                
                do
                {
                    // Saves the entity
                    try managedContext.save()
                    appDelegate.saveContext()
                }
                catch let error as NSError
                {
                    print("Could not fetch. \(error), \(error.userInfo)")
                }
            }
            
            else
            {
            
                // If there are no duplicates, folder is created successfully
                if isDuplicate != true
                {
                    // The object that the name will be saved into
                    folder = NSManagedObject(entity: entity, insertInto: managedContext)
                    
                    // Sets the name value for the folder object
                    folder!.setValue(name, forKeyPath: "name")
                    folder!.setValue(1, forKeyPath: "activated")
                    
                    // Sets the folders ID to the previous folders ID plus 1, or just sets it to 1 if there are no folders already existing
                    if folders.isEmpty == true
                    {
                        folder!.setValue(1, forKeyPath: "folderID")
                    }
                    else
                    {
                        let nextId = folders[folders.count - 1].value(forKey: "folderID") as! Int + 1
                        folder!.setValue(nextId, forKeyPath: "folderID")
                    }
                
                    do
                    {
                        // Saves the entity
                        try managedContext.save()
                        appDelegate.saveContext()
                    }
                    catch let error as NSError
                    {
                        print("Could not fetch. \(error), \(error.userInfo)")
                    }
                }
                
            }
        }
        
        catch let error as NSError
        {
          print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        dismiss(animated:true, completion: nil)

    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
