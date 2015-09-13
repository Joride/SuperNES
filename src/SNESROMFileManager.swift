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
    var saveDate : NSDate {get}
    var screenCaptureFilePath : String {get}
    var saveStateFilePath  : String {get}
}

class SNESROMFreezeState : NSObject, SNESROMSaveState
{
    var saveDate : NSDate

    // this will always return a path, it is not guarenteed that a screenshot
    // file at that path actually exists.
    var screenCaptureFilePath : String

    // this will return a path at which a savestate exists (unless the path
    // obtained from pushSaveStatePath() was not used to create a file, which is
    // something that should NOT happen).
    var saveStateFilePath  : String
    init(saveDate: NSDate, screenCaptureFilePath: String, saveStateFilePath: String)
    {
        self.saveDate = saveDate
        self.screenCaptureFilePath = screenCaptureFilePath
        self.saveStateFilePath = saveStateFilePath
    }
}


//  a ROMFile, including URLs to image, savestates and SRAM, if available
 // needs to be usable in Obj-C
class ROM :  NSObject, SNESROMFileManaging, CustomDebugStringConvertible, Comparable
{
    let ROMFileName : String
    let ROMPath : String
    var saveStates : Array<SNESROMSaveState> = Array()
    let fileManager : NSFileManager

    init(ROMFileName : String, ROMPath: String, fileManager : NSFileManager)
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
        if self.fileManager.fileExistsAtPath(saveStatesFolderPath)
        {
            do {
                saveStateStrings = try self.fileManager.contentsOfDirectoryAtPath(saveStatesFolderPath)
                for aSaveStateFileName in saveStateStrings!
                {
                    if ((aSaveStateFileName as NSString).pathExtension == "frz")
                    {
                        let state = self.newFreezeState(forSaveStatesFolderPath: saveStatesFolderPath, withSaveStateFileName: aSaveStateFileName)
                        self.saveStates.append(state)
                    }
                }

                // sort the array based on date
                self.saveStates = self.saveStates.sort({ (saveState1 : SNESROMSaveState, saveState2 : SNESROMSaveState) -> Bool in
                    // return yes if 1 is before 2
                    var orderedBefore : Bool = true

                    let ordering = saveState1.saveDate.compare(saveState2.saveDate)
                    if (ordering == .OrderedAscending)
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
        let fileExists = self.fileManager.fileExistsAtPath(path, isDirectory: nil)
        if (!fileExists)
        {
            do
            {
                try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error as NSError
            {
                NSLog("\(error.localizedDescription)")
            }

        }
    }
    func saveStatesFolderPath() -> String
    {
        let ROMFolderPath = (self.fileManager.userDocumentsDirectory as NSString).stringByAppendingPathComponent(self.ROMName)
        let saveStatesFolderPath = (ROMFolderPath as NSString).stringByAppendingPathComponent("savestates")
        return saveStatesFolderPath;
    }

    func newFreezeState(forSaveStatesFolderPath saveStatesFolderPath: String, withSaveStateFileName saveStateFileName: String?) -> SNESROMFreezeState
    {
        var saveDate : NSDate?

        let saveStateNameWithExtension : String
        if let aSaveStateName = saveStateFileName
        {
            saveStateNameWithExtension = aSaveStateName
        }
        else
        {
            let fileName =  NSUUID().UUIDString
            saveStateNameWithExtension = (fileName as NSString).stringByAppendingPathExtension("frz")!

            // this is cheating a little bit: the assumtion is that a new freezeState
            // is being created on request, and so a file will be made now
            saveDate = NSDate()
        }

        let saveStateNameWithoutExtension = (saveStateNameWithExtension as NSString).stringByDeletingPathExtension
        let screenCaptureNameWithExtension = (saveStateNameWithoutExtension as NSString).stringByAppendingPathExtension("png")!
        let fullSaveStatePath = (saveStatesFolderPath as NSString).stringByAppendingPathComponent(saveStateNameWithExtension)
        let fullScreencapturePath = (saveStatesFolderPath as NSString).stringByAppendingPathComponent(screenCaptureNameWithExtension)

        if self.fileManager.fileExistsAtPath(fullSaveStatePath)
        {
            do {
                let attributes = try self.fileManager.attributesOfItemAtPath(fullSaveStatePath)
                if let modificationDate = attributes[NSFileCreationDate] as? NSDate
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
        self.createFolderAtPathIfNecessary(saveStatesFolderPath)
        let state = self.newFreezeState(forSaveStatesFolderPath: saveStatesFolderPath, withSaveStateFileName: nil)

        self.saveStates.insert(state, atIndex: 0)
        return state
    }

    var ROMName : String{
        get {
            let nameAndExtension = self.ROMFileName.componentsSeparatedByString(".")
            let ROMName = nameAndExtension[0]
            return ROMName
        }
    }

    var imagePath : String {
        get {
            let returnPath : String
            if let imageFileName = (self.ROMName as NSString).stringByAppendingPathExtension("png")
            {
                let imagePath = (self.fileManager.userDocumentsDirectory as NSString).stringByAppendingPathComponent(imageFileName)
                let fileExists = self.fileManager.fileExistsAtPath(imagePath)
                if fileExists
                {
                    returnPath =  imagePath
                }
                else
                {
                    let placeholderImageFileName = "SNESPlaceHolder.png"
                    returnPath = (self.fileManager.userDocumentsDirectory as NSString).stringByAppendingPathComponent(placeholderImageFileName)
                }
            }
            else
            {
                let placeholderImageFileName = "SNESPlaceHolder.png"
                returnPath = (self.fileManager.userDocumentsDirectory as NSString).stringByAppendingPathComponent(placeholderImageFileName)
            }
            return returnPath
        }
    }

    var SRAMPath : String {
        get
        {
            let SRAMPath : String?
            let ROMFolderPath = (self.fileManager.userDocumentsDirectory as NSString).stringByAppendingPathComponent(self.ROMName)
            self.createFolderAtPathIfNecessary(ROMFolderPath)

            let ROMFolderPathAsNSString = ROMFolderPath as NSString
            let ROMFolderAndNamePathAsNSString = ROMFolderPathAsNSString.stringByAppendingPathExtension(self.ROMName)! as NSString
            let SRAMFilePath = ROMFolderAndNamePathAsNSString.stringByAppendingPathExtension("srm")
            
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
    lazy var fileManager = NSFileManager.defaultManager()


    // returns a ROM struct for each .SMC file found
    // in the userdocuments directory
    func ROMs() -> (Array<SNESROMFileManaging>)?
    {
        var ROMs : Array<ROM>?
        var contentError : NSError? = nil

        var contents: [AnyObject]?
        do {
            contents = try self.fileManager.contentsOfDirectoryAtPath(self.fileManager.userDocumentsDirectory)
        } catch let error as NSError {
            contentError = error
            contents = nil
        }
        if let directoryContents = contents as? Array<String>
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
                    let fullFilePath = (self.fileManager.userDocumentsDirectory as NSString).stringByAppendingPathComponent(aFileName)
                    let aRom  = ROM(ROMFileName : aFileName, ROMPath: fullFilePath, fileManager: self.fileManager)
                    ROMs?.append(aRom)
                }
            }
            ROMs = ROMs?.sort({ (rom1: ROM, rom2: ROM) -> Bool in
                return rom1 < rom2
            })
        }
        else
        {
            print("ERROR: could not get contents of directory: \(contentError!)")
        }
        return ROMs
    }
}




extension NSFileManager
{
    var userDocumentsDirectory : String {
        get {
            let URLs = self.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
            let URL : NSURL? = URLs.last!
            // Userdocumentsdir alway exists, so i'm taking the
            // bold risk of force-unwrapping this optional.
            return URL!.path!
        }
    }
}













