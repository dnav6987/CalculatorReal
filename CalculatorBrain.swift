//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Dan Navarro on 2/2/16.
//  Copyright © 2016 Dan Navarro. All rights reserved.
//

import Foundation

class CalculatorBrain : CustomStringConvertible
{
    private var opStack = [Op]()    // Stack of Ops, where Ops are operands and operations
    private var knownOps = [String:Op]()    // Dictionary of operation symbol to operation function used by calculator
    private var variables = [String: Double?]() // Dictionary of variables to their values
    
    var program: AnyObject {    // guarunteed to be a PropertyList
        get {
            return opStack.map { $0.description }
        }
        set {
            if let opSymbols = newValue as? Array<String> {
                var newOpStack = [Op]() // if want to actually load it, need to clear actual opStack and push to that
                for opSymbol in opSymbols {
                    if let op = knownOps[opSymbol] {
                        newOpStack.append(op)
                    } else if let operand = NSNumberFormatter().numberFromString(opSymbol)?.doubleValue {
                        newOpStack.append(.Operand(operand))
                    }
                }
            }
        }
    }
    
    // set the knownOps
    init() {
        func learnOp(op: Op) {  // alternate way of adding on Op, not used in this project
            knownOps[op.description] = op
        }
        
        knownOps["×"] = Op.BinaryOperation("×", *)
        knownOps["÷"] = Op.BinaryOperation("÷") {$1 / $0}
        knownOps["+"] = Op.BinaryOperation("+", +)
        knownOps["-"] = Op.BinaryOperation("-") {$1 - $0}
        knownOps["√"] = Op.UnaryOperation("√", sqrt)
        knownOps["sin"] = Op.UnaryOperation("sin", sin)
        knownOps["cos"] = Op.UnaryOperation("cos", cos)
        knownOps["π"] = Op.ConstantOrVariable("π", M_PI)
    }
    
    private enum Op : CustomStringConvertible { // What we save to the opStack. operands and operations
        case Operand(Double)    // Operands are just numbers
        case UnaryOperation(String, Double -> Double)   // unary operations
        case BinaryOperation(String, (Double, Double) -> Double)    // binary operations
        case ConstantOrVariable(String, Double?)    // constant and variable symbols can just be replaced by their number so they are grouped together
        
        var description: String {   // how to describe Op as a String
            get {
                switch self {
                case .Operand(let operand):
                    // for integers we don't want to display decimal points, which is a default for doubles. Only convert to Int however,
                    // if the double can be casted to an Int (i.e. it is less than Int.max)
                    if operand%1 == 0 && operand < Double(Int.max) {
                        return "\(Int(operand))"
                    } else {
                        return "\(operand)"
                    }
                case .UnaryOperation(let symbol, _):
                    return symbol
                case .BinaryOperation(let symbol, _):
                    return symbol
                case .ConstantOrVariable(let symbol, _):
                    return symbol
                }
            }
        }
        
        var precedence: Int {   // order of operations. for deciding where to add parenthesis
            get {
                switch self {
                case .Operand(_):
                    return Int.max
                case .UnaryOperation(_, _): // lowest priorty because they will by defualt provide parenthesis and we don't want redundant parenthesis
                    return 0
                case .BinaryOperation(let symbol, _):   // + and - are the lowest
                    if symbol == "+" || symbol == "-" {
                        return 0
                    }
                    return 1    // but x and / are only one higher
                case .ConstantOrVariable(_, _):
                    return Int.max
                }
            }
        }
        
    }
    
    // push an operand (number) onto the stack and evaluate the result
    func pushOperand(operand: Double) -> Double? {
        opStack.append(Op.Operand(operand))
        return evaluate()
    }
    
    // push an operand (variable) onto the stack and evaluate the result
    func pushOperand(operand: String) -> Double? {
        if let constantOp = knownOps[operand] { // constants by convention will have entries in knownOps
            opStack.append(constantOp)
        } else {    // variables by convention will have a nil value as their values are stores in variables dictionary
            opStack.append(Op.ConstantOrVariable(operand, nil))
        }
        return evaluate()
    }
    
    // save a variable and evaluate the opStack with this new value
    func setVariable(variable: String, value: Double?) -> Double? {
        variables[variable] = value
        return evaluate()
    }
    
    // push the operator onto the stack and evaluate
    func performOperation(symbol: String) -> Double? {
        if let operation = knownOps[symbol] {   // make sure that it is a valid operation
            opStack.append(operation)
            return evaluate()
        }
        return nil  // invalid operation
    }
    
    // how to represent a CalculatorBrain as a String. Want to make sure we show the entire stack, all the way to the bottom
    // but description can only return the last expression on the stack we keep calling descrition until each expression
    // is included
    var description: String {
        var lastCompletedExpressionIndex = opStack.count    // Index of the bottom most Op in opStack of the last expression
        var result: String = "" // we will append expressions to this
        while lastCompletedExpressionIndex > 0 {    // until the expressions are all included
            let ops = opStack  // make a copy
            let remainingExpressions: Array<Op> = Array(ops[0..<lastCompletedExpressionIndex])  // sub array of opStack that does not include already done expressions
            let desc = description(remainingExpressions, currentPrecedence: 0)
            lastCompletedExpressionIndex = desc.index
            result = desc.result + ", " + result    // separate expressions with commas
        }
        
        return String(result.characters.dropLast(2))    // remove the unnecessary comma after the most recent expression
    }
    
    // clear the opstack
    func clear() {
        opStack = [Op]()
        variables = [String: Double?]()
    }

    // recursive function to describe the top expressions on the Stack. It takes as parameters an Op Stack and the
    // current precedence. If a higher precedence operation calls a lower one, than the lower precedence operation needs
    // parenthesis.
    private func description(ops: [Op], currentPrecedence: Int) -> (result: String, remainingOps: [Op], index: Int) {
        if !ops.isEmpty {
            var remainingOps = ops  // make a copy
            let op = remainingOps.removeLast()  // pop
            
            switch op {
            case .Operand(_): // operand
                return ("\(op)", remainingOps, remainingOps.count)
            case .UnaryOperation(_, _): // unary operator
                let operandEvaluation = description(remainingOps, currentPrecedence: op.precedence)  // recursively get the operand for the operator
                let result = "\(op)(" + operandEvaluation.result + ")"  // always surround operand with parenthesis
                return (result, operandEvaluation.remainingOps, operandEvaluation.index)
            case .BinaryOperation(_, _):    // binary operator
                let operandEvaluation = description(remainingOps, currentPrecedence: op.precedence) // first operand
                let operandEvaluation2 = description(operandEvaluation.remainingOps, currentPrecedence: op.precedence)  // second operand
                var result = ""
                if op.precedence < currentPrecedence {  // only surround with parenthesis if inside a high order function
                    result = "(" + operandEvaluation2.result + " \(op) " + operandEvaluation.result + ")"
                } else {
                    result = operandEvaluation2.result + " \(op) " + operandEvaluation.result
                }
                return (result, operandEvaluation2.remainingOps, operandEvaluation2.index)
            case .ConstantOrVariable(_, _):   // constants and variables
                return ("\(op)", remainingOps, remainingOps.count)
            }
        }
        
        return ("?",ops, 0)
    }
    
    // helper function for evaluate
    func evaluate() -> Double? {
        return evaluate(opStack).result
    }
    
    // recursive evaluate function
    private func evaluate(ops: [Op]) -> (result: Double?, remainingOps: [Op]) {
        if !ops.isEmpty {   // base case, cannot operate on nothing
            var remainingOps = ops  // make a copy so we can change it
            let op = remainingOps.removeLast()
            
            switch op {
            case .Operand(let operand): // operand
                return (operand, remainingOps)  // just return the operand and the remaining ops
            case .UnaryOperation(_, let operation): // unary operator
                let operandEvaluation = evaluate(remainingOps)  // recursively get the operand for the operator
                if let operand = operandEvaluation.result { // make sure it had a valid result
                    return (operation(operand), operandEvaluation.remainingOps) // operate on the operand
                }
            case .BinaryOperation(_, let operation):    // binary operator
                let operandEvaluation = evaluate(remainingOps)  // recursively get the first operand
                if let operand = operandEvaluation.result {
                    let operandEvaluation2 = evaluate(operandEvaluation.remainingOps)   // recursively get the second operand
                    if let operand2 = operandEvaluation2.result {
                        return (operation(operand, operand2), operandEvaluation2.remainingOps)  // operate on the two operands
                    }
                }
            case .ConstantOrVariable(let variable, let value):   // constants and variables
                if value != nil {   // this is the case for constants
                    return (value, remainingOps)
                } else if let variableValue = variables[variable] { // check if it is a defined variable
                    return (variableValue, remainingOps)
                }
            }
        }
        return (nil, ops)
    }
}