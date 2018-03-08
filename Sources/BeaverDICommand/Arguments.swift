//
//  Arguments.swift
//  BeaverDICommand
//
//  Created by Théophane Rupin on 3/7/18.
//

import Foundation
import Commander

struct InputPathsArgument: ArgumentConvertible {
    
    let values: [String]
    
    init(parser: ArgumentParser) throws {
        guard !parser.isEmpty else {
            throw ArgumentError.missingValue(argument: "input_paths")
        }
        
        var values: [String] = []
        
        while let value = parser.shift() {
            values += [value]
        }
        
        self.values = values
    }
    
    var description: String {
        return values.description
    }
}
