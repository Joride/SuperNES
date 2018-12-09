//
//  SNESROMFileManager.swift
//  SuperNES
//
//  Created by Joride on 28-06-15.
//  Copyright (c) 2015 KerrelInc. All rights reserved.
//

import Foundation

/*!
    === ROM and image files ===
    ===========================
-   SNES ROM files MUST have a '.SMC' or '.smc' extension to be considered
    a SNES ROM.
-   SNES ROM files have to be stored in the userdocuments directory (this can be
    done by users via iTunes filesharing).
-   Image files for the ROMS must be named identical to the ROM name, except for
    the extension.
-   Image files have to be stored in the userdocuments directory (this can be
    done by users via iTunes filesharing).
-   Imagefiles must have an extension of '.png' to be used as image.

   
    === in-game save files (SRAM) ===
    =================================
    These are the save-files that are stored on the cartridge when using a real
    SNES console.
-   there is always only one of these files per ROM (just like with the real
    SNES.
-   the in-game save files are stored inside a folder with the name of the ROM
-   the filename itself is the name of the ROM, but with the extension '.srm'.

    
    === save-state files ===
    ========================
    These are files that are saved to freeze the gamestate at a certain moment.
    This is a feature that is possible in emulation, and was not present on a 
    real SNES.
-   There can be many save-state files per ROM
-   the save-state files are stored inside a folder with the name 'savestates'
    which is inside a folder with the name of the ROM in the userdocuments
    directory
-   the name of savestates files is a random string (UUID), with the extension
    'frz'.
*/

@objc protocol SNESROMFileManaging : NSObjectProtocol
{
    var ROMName : String {get}
    var imagePath : String {get}
    var ROMPath : String {get}
    var SRAMPath : String {get}
    var saveStates : Array<SNESROMSaveState> {get}

    // this method returns a path to which to save a new save game.
    // It is expected that a file WILL actually be saved there immediately after
    func pushSaveStatePath() -> SNESROMSaveState
}

@objc protocol SNESROMSaveState : NSObjectProtocol
{
    var saveDate : Date {get}
    var screenCaptureFilePath : String {get}
    var saveStateFilePath  : String {get}
}

class SNESROMFreezeState : NSObject, SNESROMSaveState
{
    var saveDate : Date

    // this will always return a path, it is not guarenteed that a screenshot
    // file at that path actually exists.
    var screenCaptureFilePath : String

    // this will return a path at which a savestate exists (unless the path
    // obtained from pushSaveStatePath() was not used to create a file, which is
    // something that should NOT happen).
    var saveStateFilePath  : String
    init(saveDate: Date, screenCaptureFilePath: String, saveStateFilePath: String)
    {
        self.saveDate = saveDate
        self.screenCaptureFilePath = screenCaptureFilePath
        self.saveStateFilePath = saveStateFilePath
    }
}


//  a ROMFile, including URLs to image, savestates and SRAM, if available
 // needs to be usable in Obj-C
class ROM :  NSObject, SNESROMFileManaging, Comparable
{
    let ROMFileName : String
    let ROMPath : String
    var saveStates : Array<SNESROMSaveState> = Array()
    let fileManager : FileManager

    init(ROMFileName : String,
         ROMPath: String,
         fileManager : FileManager)
    {
        self.ROMFileName = ROMFileName
        self.ROMPath = ROMPath
        self.fileManager = fileManager
        super.init()
        self.loadExistingSaveStatePaths()
    }

    func loadExistingSaveStatePaths()
    {
        let saveStatesFolderPath = self.saveStatesFolderPath()




        var saveStateStrings:[String]? = nil
        if self.fileManager.fileExists(atPath: saveStatesFolderPath)
        {
            do {
                saveStateStrings = try self.fileManager.contentsOfDirectory(atPath: saveStatesFolderPath)
                for aSaveStateFileName in saveStateStrings!
                {
                    if ((aSaveStateFileName as NSString).pathExtension == "frz")
                    {
                        let state = self.newFreezeState(forSaveStatesFolderPath: saveStatesFolderPath, withSaveStateFileName: aSaveStateFileName)
                        self.saveStates.append(state)
                    }
                }

                // sort the array based on date
                saveStates = saveStates.sorted(by: {
                    (saveState1: SNESROMSaveState, saveState2: SNESROMSaveState) -> Bool in
                    // return yes if 1 is before 2
                    var orderedBefore : Bool = true
                    
                    let ordering = saveState1.saveDate.compare(saveState2.saveDate)
                    if (ordering == .orderedAscending)
                    {
                        orderedBefore = false
                    }
                    return orderedBefore
                })
            }
            catch let error as NSError
            {
                print("ERROR getting contentsOfDirectoryAtPath: \(error.description)")
            }
        }
    }

    func createFolderAtPathIfNecessary(path : String)
    {
        let fileExists = self.fileManager.fileExists(atPath: path, isDirectory: nil)
        if (!fileExists)
        {
            do
            {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error as NSError
            {
                NSLog("\(error.localizedDescription)")
            }

        }
    }
    func saveStatesFolderPath() -> String
    {
        let ROMFolderPath = (self.fileManager.userDocumentsDirectory as NSString).appendingPathComponent(self.ROMName)
        let saveStatesFolderPath = (ROMFolderPath as NSString).appendingPathComponent("savestates")
        return saveStatesFolderPath;
    }

    func newFreezeState(forSaveStatesFolderPath saveStatesFolderPath: String, withSaveStateFileName saveStateFileName: String?) -> SNESROMFreezeState
    {
        var saveDate : Date?

        let saveStateNameWithExtension : String
        if let aSaveStateName = saveStateFileName
        {
            saveStateNameWithExtension = aSaveStateName
        }
        else
        {
            let fileName =  NSUUID().uuidString
            saveStateNameWithExtension = (fileName as NSString).appendingPathExtension("frz")!

            // this is cheating a little bit: the assumtion is that a new freezeState
            // is being created on request, and so a file will be made now
            saveDate = Date()
        }

        let saveStateNameWithoutExtension = (saveStateNameWithExtension as NSString).deletingPathExtension
        let screenCaptureNameWithExtension = (saveStateNameWithoutExtension as NSString).appendingPathExtension("png")!
        let fullSaveStatePath = (saveStatesFolderPath as NSString).appendingPathComponent(saveStateNameWithExtension)
        let fullScreencapturePath = (saveStatesFolderPath as NSString).appendingPathComponent(screenCaptureNameWithExtension)

        if self.fileManager.fileExists(atPath: fullSaveStatePath)
        {
            do {
                let attributes = try self.fileManager.attributesOfItem(atPath: fullSaveStatePath)
                if let modificationDate = attributes[FileAttributeKey.creationDate] as? Date
                {
                    saveDate = modificationDate
                }
                else
                {
                    print("ERROR: no modification date present in file attributes")
                }
            } catch let error as NSError {
                print("ERROR: could not get attributes for existing item at '\(fullSaveStatePath)': \(error)")
            }
        }

        if ((nil != saveStateFileName) &&
            (nil == saveDate))
        {
            print("ERROR: there is a saveStateFileName, but no date for this creation file was found");
        }

        let state = SNESROMFreezeState(saveDate: saveDate!, screenCaptureFilePath: fullScreencapturePath, saveStateFilePath: fullSaveStatePath)

        return state
    }


    // this method returns a path to which to save a new save game.
    // An instance of this class WILL expect this to be done immediately after 
    // this method returns
    func pushSaveStatePath() -> SNESROMSaveState
    {
        let saveStatesFolderPath = self.saveStatesFolderPath()
        self.createFolderAtPathIfNecessary(path: saveStatesFolderPath)
        let state = self.newFreezeState(forSaveStatesFolderPath: saveStatesFolderPath, withSaveStateFileName: nil)

        self.saveStates.insert(state, at: 0)
        return state
    }

    var ROMName : String{
        get {
            let nameAndExtension = self.ROMFileName.components(separatedBy: ".")
            let ROMName = nameAndExtension[0]
            return ROMName
        }
    }

    var imagePath : String {
        get {
            var returnPath : String = ""
            
            if let imageFileName = (self.ROMName as NSString).appendingPathExtension("png")
            {
                var imagePath = (self.fileManager.userDocumentsDirectory as NSString).appendingPathComponent(imageFileName)
                let fileExists = self.fileManager.fileExists(atPath: imagePath)
                if fileExists
                {
                    returnPath =  imagePath
                }
                else
                {
                    if let resourcePath = Bundle.main.resourcePath
                    {
                        imagePath = (resourcePath as NSString).appendingPathComponent(imageFileName)
                        let fileExists = self.fileManager.fileExists(atPath: imagePath)
                        if fileExists
                        {
                            returnPath =  imagePath
                        }
                        else
                        {
                            let placeholderImageFileName = "SNESPlaceHolder.png"
                            returnPath = (resourcePath as NSString).appendingPathComponent(placeholderImageFileName)
                        }
                    }
                }
            }
            else
            {
                let placeholderImageFileName = "SNESPlaceHolder.png"
                returnPath = (self.fileManager.userDocumentsDirectory as NSString).appendingPathComponent(placeholderImageFileName)
            }
            return returnPath
        }
    }

    var SRAMPath : String {
        get
        {
            let ROMFolderPath = (self.fileManager.userDocumentsDirectory as NSString).appendingPathComponent(self.ROMName)
            self.createFolderAtPathIfNecessary(path: ROMFolderPath)

            let ROMFolderPathAsNSString = ROMFolderPath as NSString
            let ROMFolderAndNamePathAsNSString = ROMFolderPathAsNSString.appendingPathExtension(self.ROMName)! as NSString
            let SRAMFilePath = ROMFolderAndNamePathAsNSString.appendingPathExtension("srm")
            
            return SRAMFilePath!
        }
    }
    override var debugDescription : String{
        get {
            return "ROMFileName: '\(self.ROMFileName)'SRAMURL: \(self.SRAMPath) imageURL: \(self.imagePath) saveStateURLs: \(self.saveStates)"
        }
    }
}
func < (lhs: ROM, rhs: ROM) -> Bool {
    return lhs.ROMFileName < rhs.ROMFileName
}
func >=(lhs: ROM, rhs: ROM) -> Bool
{
    return lhs.ROMFileName >= rhs.ROMFileName
}
func >(lhs: ROM, rhs: ROM) -> Bool
{
    return lhs.ROMFileName > rhs.ROMFileName
}
func ==(lhs: ROM, rhs: ROM) -> Bool
{
    return  lhs.ROMFileName == rhs.ROMFileName
}

class SNESROMFileManager : NSObject
{
    lazy var fileManager = FileManager.default
    
    private var loadedRoms: [ROM]? = nil
    
    // returns a ROM struct for each .SMC file found
    // in the userdocuments directory
    @objc func ROMs() -> (Array<SNESROMFileManaging>)?
    {
        if nil != loadedRoms { return loadedRoms! }
        
        
        var ROMs : Array<ROM>?
        var contentError : NSError? = nil
        
        var contents: [String]?
        if let resourceURL = Bundle.main.resourceURL
        {
            do
            {
                contents = try fileManager.contentsOfDirectory(atPath: resourceURL.path)
                if let directoryContents = contents
                {
                    for aFileName in directoryContents
                    {
                        if ROMs == nil
                        {
                            ROMs = Array()
                        }
                        
                        let fileExtension = (aFileName as NSString).pathExtension
                        if (fileExtension == "smc" ||
                            fileExtension == "SMC")
                        {
                            let fullFilePath = (resourceURL.path as NSString).appendingPathComponent(aFileName)
                            let aRom  = ROM(ROMFileName : aFileName,
                                            ROMPath: fullFilePath,
                                            fileManager: self.fileManager)
                            ROMs?.append(aRom)
                        }
                    }
                    
                    ROMs = ROMs?.sorted(by: {
                        (rom1: ROM, rom2:ROM) -> Bool in
                        return rom1 < rom2
                    })
                }
                else
                {
                    print("ERROR: could not get contents of directory: \(contentError!)")
                }
            }
            catch
            {
                print("\(error)")
            }
            loadedRoms = ROMs
            return loadedRoms
        }
        
        
        do {
            contents = try self.fileManager.contentsOfDirectory(atPath: self.fileManager.userDocumentsDirectory)
            if let directoryContents = contents
            {
                for aFileName in directoryContents
                {
                    if ROMs == nil
                    {
                        ROMs = Array()
                    }
                    
                    let fileExtension = (aFileName as NSString).pathExtension
                    if (fileExtension == "smc" ||
                        fileExtension == "SMC")
                    {
                        let fullFilePath = (self.fileManager.userDocumentsDirectory as NSString).appendingPathComponent(aFileName)
                        let aRom  = ROM(ROMFileName : aFileName, ROMPath: fullFilePath, fileManager: self.fileManager)
                        ROMs?.append(aRom)
                    }
                }
                
                ROMs = ROMs?.sorted(by: {
                    (rom1: ROM, rom2:ROM) -> Bool in
                    return rom1 < rom2
                })
            }
            else
            {
                print("ERROR: could not get contents of directory: \(contentError!)")
            }
            
        } catch let error as NSError {
            contentError = error
            contents = nil
        }
        
        loadedRoms = ROMs
        return loadedRoms
    }
}




extension FileManager
{
    var userDocumentsDirectory : String {
        get {
            let URLs = self.urls(for: .documentDirectory, in: .userDomainMask)
            let URL : NSURL? = URLs.last! as NSURL
            // Userdocumentsdir alway exists, so i'm taking the
            // bold risk of force-unwrapping this optional.
            return URL!.path!
        }
    }
    
    var resourcesDirectory : String {
        get {
            let URLs = self.urls(for: .documentDirectory, in: .userDomainMask)
            let URL : NSURL? = URLs.last! as NSURL
            // Userdocumentsdir alway exists, so i'm taking the
            // bold risk of force-unwrapping this optional.
            return URL!.path!
        }
    }
}













