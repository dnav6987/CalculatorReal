//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Dan Navarro on 2/2/16.
//  Copyright © 2016 Dan Navarro. All rights reserved.
//

import Foundation

class CalculatorBrain
{
    private var opStack = [Op]()    // Stack of Ops, where Ops are operands or operations
    private var knownOps = [String:Op]()    // Dictionary of operation symbol to operation function used by calculator
    private var variables = [String: Double?]() // Dictionary of variables
    
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
    
    private enum Op : CustomStringConvertible {
        case Operand(Double)    // Operands are just digits for now
        case UnaryOperation(String, Double -> Double)   // unary operations
        case BinaryOperation(String, (Double, Double) -> Double)    // binary operations
        case ConstantOrVariable(String, Double?)    // constants and variables can just be replaced by their number so group together
        
        var description: String {
            get {
                switch self {
                case .Operand(let operand):
                    return "\(operand)"
                case .UnaryOperation(let symbol, _):
                    return symbol
                case .BinaryOperation(let symbol, _):
                    return symbol
                case .ConstantOrVariable(let symbol, _):
                    return symbol
                }
            }
        }
    }
    
    // initialize the dictionaries
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
    
    // clear the opstack
    func clear() {
        opStack = [Op]()
        variables = [String: Double?]()
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
    
    func setVariable(variable: String, value: Double?) {
        variables[variable] = value
    }
    
    // push the operator onto the stack and evaluate
    func performOperation(symbol: String) -> Double? {
        if let operation = knownOps[symbol] {   // make sure that it is a valid operation
            opStack.append(operation)
            return evaluate()
        }
        return nil  // invalid operation
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