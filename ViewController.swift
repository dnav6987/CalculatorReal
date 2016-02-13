//
//  ViewController.swift
//  Calculator
//
//  Created by Dan Navarro on 1/28/16.
//  Copyright © 2016 Dan Navarro. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var display: UILabel!    // the main display
    @IBOutlet weak var history: UITextView! // the history. it is scrollable
    
    let ERROR = "ERR"   // display string when there is an error
    var userIsInTheMiddleOfTypingANumber = false    // is the user typing a number?
    var brain = CalculatorBrain()   // the model
    
    var displayValue: Double? { // for getting and setting the display text
        get {
            if display.text! == ERROR {
                return nil
            }
            return NSNumberFormatter().numberFromString(display.text!)!.doubleValue // convert the text to a Double
        }
        set {
            if newValue != nil {
                // for integers we don't want to display decimal points, which is a default for doubles. Only convert to Int however,
                // if the double can be casted to an Int (i.e. it is less than Int.max)
                if newValue!%1 == 0 && newValue! < Double(Int.max) {
                    display.text = "\(Int(newValue!))"
                } else {
                    display.text = "\(newValue!)"
                }
            } else {
                display.text = ERROR
            }
            userIsInTheMiddleOfTypingANumber = false
            record()    // log the new value to history
        }
    }
    
    // allows the user to move onto the next number or operation
    @IBAction func enter() {
        userIsInTheMiddleOfTypingANumber = false
        
        if displayValue != nil {
            displayValue = brain.pushOperand(displayValue!)   // push the current number
        }
    }
    
    // log a string to the history on a new line
    func record() {
        history.text = history.text! + "\n\(brain) ="   // append the description of the brain
        history.scrollRangeToVisible(NSMakeRange(0, history.text.characters.count)) // scroll the view to the bottom
    }
    
    // when a digit or '.' button is pressed
    @IBAction func digitPressed(sender: UIButton) {
        let digit = sender.currentTitle!    // get the number that was pressed
        
        if userIsInTheMiddleOfTypingANumber {
            if digit != "." || display.text!.rangeOfString(".") == nil {    // make sure a number has at most one decimal place
                display.text = display.text! + digit    // append the digit
            }
        } else {    // first digit of the number
            if digit == "." {
                display.text = "0."   // if starting with a '.', make it '0.'
            } else {
                display.text = digit    // just set the display to this digit
            }
            userIsInTheMiddleOfTypingANumber = true
        }
    }
    
    // operands reperesented by a symbol (i.e. constants and variables)
    @IBAction func specialOperandPressed(sender: UIButton) {
        if userIsInTheMiddleOfTypingANumber {
            enter()
            userIsInTheMiddleOfTypingANumber = false
        }
        displayValue = brain.pushOperand(sender.currentTitle!)
    }
    
    // save the current displayValue as the value of the specified variable
    @IBAction func saveVariable(sender: UIButton) {
        if displayValue != nil {    // do not want to save the variable in this case
            // By convention the button will have an arrow symbol and then the name of the variable so we need to extract the substring after the arrow
            let buttonTitle = sender.currentTitle!
            let variable = buttonTitle.substringFromIndex(buttonTitle.startIndex.advancedBy(1)) // substring from index 1 to end
            displayValue = brain.setVariable(variable, value: displayValue!)   // save the variable in the brain
            userIsInTheMiddleOfTypingANumber = false
        }
    }
    
    // opertor was pressed
    @IBAction func operate(sender: UIButton) {
        if userIsInTheMiddleOfTypingANumber {   // allow the user to operate without having to press enter
            enter()
        }
        if let operation = sender.currentTitle {
            displayValue = brain.performOperation(operation) // perform the operation and get the result
        }
    }
    
    // reset to initial settings
    @IBAction func allClear(sender: UIButton) {
        userIsInTheMiddleOfTypingANumber = false
        displayValue = 0
        history.text = "→"
        brain.clear()
    }
}

