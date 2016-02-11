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
    
    // for getting and setting the display text
    var displayValue: Double? {
        get {
            if display.text! == ERROR {
                return nil
            }
            return NSNumberFormatter().numberFromString(display.text!)!.doubleValue
        }
        set {
            if newValue != nil {
                if newValue!%1 == 0 && newValue! < Double(Int.max) {    // it is an integer so we don't want to display decimal points, which is a default for doubles
                    display.text = "\(Int(newValue!))"  // hopefully all doubles can be converted properly to ints
                } else {
                    display.text = "\(newValue!)"
                }
            } else {
                display.text = ERROR
            }
            userIsInTheMiddleOfTypingANumber = false
        }
    }
    
    // when a digit button is pressed
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
                display.text = digit
            }
            userIsInTheMiddleOfTypingANumber = true
        }
    }
    
    // allows the user to move onto the next number or operation
    @IBAction func enter() {
        userIsInTheMiddleOfTypingANumber = false
        
        if displayValue != nil {
            displayValue = brain.pushOperand(displayValue!)   // push the current number
            record(display.text!)   // log to the history
        }
    }
    
    @IBAction func saveVariable(sender: UIButton) {
        if displayValue != nil {
            let variable = "M" // TODO this is only cause i don't want the arrow
            brain.setVariable(variable, value: displayValue!)
            displayValue = brain.evaluate()
            userIsInTheMiddleOfTypingANumber = false
        }
    }
    
    @IBAction func pushSpecialOperand(sender: UIButton) { // TODO maybe don't want this
        userIsInTheMiddleOfTypingANumber = false
        displayValue = brain.pushOperand(sender.currentTitle!)
    }
    
    // opertor was pressed
    @IBAction func operate(sender: UIButton) {
        if userIsInTheMiddleOfTypingANumber {   // allow the user to operate without having to press enter
            enter()
        }
        
        if let operation = sender.currentTitle {
            record(operation)   // log the operation to the history
            record("=") // log an '=' to show that an operation was evaluated
            
            if let result = brain.performOperation(operation) { // perform the operation and get the result
                displayValue = result
            } else {
                displayValue = nil    // default for invalid results
            }
            
            record(display.text!)
        }
    }
    
    // log a string to the history on a new line
    func record(thisPieceOfHistory: String) {
         history.text = history.text! + "\n\(thisPieceOfHistory)"
    }
    
    // reset to initial settings
    @IBAction func allClear(sender: UIButton) {
        userIsInTheMiddleOfTypingANumber = false
        displayValue = 0
        history.text = "History"
        brain.clear()
    }
}

