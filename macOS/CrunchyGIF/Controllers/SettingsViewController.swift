//
//  SettingsViewController.swift
//  CrunchyGIF
//
//  Created by Josh Holtz on 12/31/19.
//  Copyright © 2019 Josh Holtz. All rights reserved.
//

import Cocoa

struct Setting {
    enum Kind: String {
        case defaults, custom
        
        var fps: Int {
            get {
                if let value = UserDefaults.standard.object(forKey: "\(rawValue)-fps") as? Int {
                    return value
                } else {
                    return 15
                }
            }
            set {
                UserDefaults.standard.set(newValue, forKey: "\(rawValue)-fps")
            }
        }
        
        var width: Int {
            get {
                if let value = UserDefaults.standard.object(forKey: "\(rawValue)-width") as? Int {
                    return value
                } else {
                    return 400
                }
            }
            set {
                UserDefaults.standard.set(newValue, forKey: "\(rawValue)-width")
            }
        }
        
        var height: Int {
            get {
                if let value = UserDefaults.standard.object(forKey: "\(rawValue)-height") as? Int {
                    return value
                } else {
                    return -1
                }
            }
            set {
                UserDefaults.standard.set(newValue, forKey: "\(rawValue)-height")
            }
        }
    }
    
    let fps: Int
    let width: Int
    let height: Int
    
    private init(fps: Int, width: Int, height: Int) {
        self.fps = fps
        self.width = width
        self.height = height
    }
    
    static func fetch(kind: Kind) -> Setting {
        let fps = kind.fps
        let width = kind.width
        let height = kind.height
        
        return Setting(fps: fps, width: width, height: height)
    }
}

class SettingsViewController: NSViewController {
    
    typealias OnBack = () -> Void
    var onBack: OnBack?
    
    typealias OnDone = () -> Void
    var onDone: OnDone?
    
    var kind: Setting.Kind?

    @IBOutlet weak var fpsTextView: NSTextField!
    @IBOutlet weak var widthTextView: NSTextField!
    @IBOutlet weak var heightTextView: NSTextField!
    @IBOutlet weak var saveButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        fpsTextView.formatter = OnlyIntegerValueFormatter()
        widthTextView.formatter = OnlyIntegerValueFormatter()
        heightTextView.formatter = OnlyIntegerValueFormatter()
    }
    
    @IBAction func onClickSave(_ sender: Any) {
        kind?.fps = fpsTextView.integerValue
        kind?.width = widthTextView.integerValue
        kind?.height = heightTextView.integerValue
        
        onDone?()
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        onBack?()
    }
    
    func loadSetting(kind: Setting.Kind) {
        self.kind = kind
        
        switch kind {
        case .custom:
            saveButton.title = "Make GIF"
        case .defaults:
            saveButton.title = "Save"
        }
        
        fpsTextView.integerValue = kind.fps
        widthTextView.integerValue = kind.width
        heightTextView.integerValue = kind.height
    }
}

class OnlyIntegerValueFormatter: NumberFormatter {

    override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {

        // Ability to reset your field (otherwise you can't delete the content)
        // You can check if the field is empty later
        if partialString.isEmpty {
            return true
        }
        
        if partialString == "-" {
            return true
        }

        // Optional: limit input length
        /*
        if partialString.characters.count>3 {
            return false
        }
        */

        // Actual check
        return Int(partialString) != nil
    }
}
