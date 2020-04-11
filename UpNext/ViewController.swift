//
//  ViewController.swift
//  TextTransform
//
//  Created by Koen Vendrik on 2020-04-10.
//  Copyright © 2020 Koen Vendrik. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTextFieldDelegate {
    @IBOutlet weak var input: NSTextField!
    @IBOutlet weak var type: NSSegmentedControl!
    @IBOutlet weak var output: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        typeChanged(self)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    
    @IBAction func typeChanged(_ sender: Any) {
        switch type.selectedSegment {
            case 0:
                output.stringValue = bold(input.stringValue)
            case 1:
                output.stringValue = underline(input.stringValue)
            case 2:
                output.stringValue = italic(input.stringValue)
            default:
                output.stringValue = bold(input.stringValue)
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        typeChanged(self)
    }
    
    
    @IBAction func copyToPaste(_ sender: Any) {
    }
    
    func bold(_ input: String) -> String {
        return "bold: " + input;
    }
    
    func underline(_ input: String) -> String {
        return "underline: " + input;
    }

    func italic(_ input: String) -> String {
        return "italic: " + input;
    }
}

