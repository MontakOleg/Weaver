//
//  SourceKitTypeDeclaration.swift
//  WeaverCodeGen
//
//  Created by Théophane Rupin on 2/22/18.
//

import Foundation
import SourceKittenFramework

struct SourceKitDeclaration {
    
    let offset: Int
    let length: Int
    let type: SwiftType
    let hasBody: Bool
    let accessLevel: AccessLevel
    let isInjectable: Bool
    let doesSupportObjc: Bool
    
    init?(_ dictionary: [String: Any], lineString: String = "") {
        
        guard let kindString = dictionary[SwiftDocKey.kind.rawValue] as? String,
              let kind = SwiftDeclarationKind(rawValue: kindString) else {
            return nil
        }
        
        let inheritedTypes: [String]
        if let inheritedTypeDicts = dictionary[SwiftDocKey.inheritedtypes.rawValue] as? [[String: Any]] {
            inheritedTypes = inheritedTypeDicts.compactMap { $0[SwiftDocKey.name.rawValue] as? String }
        } else {
            inheritedTypes = []
        }

        guard let offset = dictionary[SwiftDocKey.offset.rawValue] as? Int64 else {
            return nil
        }
        self.offset = Int(offset)
        
        
        guard let length = dictionary[SwiftDocKey.length.rawValue] as? Int64 else {
            return nil
        }
        self.length = Int(length)

        switch kind {
        case .class,
             .struct:
            isInjectable = true
            doesSupportObjc = false

        case .extension where inheritedTypes.first { $0.hasSuffix("ObjCDependencyInjectable") } != nil:
            isInjectable = true
            doesSupportObjc = true

        case .enum,
             .extension:
            isInjectable = false
            doesSupportObjc = false
            
        default:
            return nil
        }

        do {
            guard let typeString = dictionary[SwiftDocKey.name.rawValue] as? String,
                  let type = try SwiftType(typeString) else {
                return nil
            }

            if let matches = try NSRegularExpression(pattern: "(\(type.name)<.*>)").matches(in: lineString),
               let _type = try SwiftType(matches[0]) {
                self.type = _type
            } else {
                self.type = type
            }
        } catch {
            return nil
        }
        
        hasBody = dictionary.keys.contains(SwiftDocKey.bodyOffset.rawValue)
        
        if let attributeKindString = dictionary["key.accessibility"] as? String {
            self.accessLevel = AccessLevel(attributeKindString)
        } else {
            accessLevel = .default
        }
    }
}

// MARK: - Conversion

private extension Int {
    /// Default value used until the real value gets determined later on.
    static let defaultLine = -1
}

extension SourceKitDeclaration {
    
    var toToken: AnyTokenBox {
        if isInjectable {
            let injectableType = InjectableType(type: type, accessLevel: accessLevel, doesSupportObjc: doesSupportObjc)
            return TokenBox(value: injectableType, offset: offset, length: length, line: .defaultLine)
        } else {
            return TokenBox(value: AnyDeclaration(), offset: offset, length: length, line: .defaultLine)
        }
    }
    
    var endToken: AnyTokenBox? {
        guard hasBody == true else {
            return nil
        }
        
        let offset = self.offset + length - 1
        if isInjectable {
            return TokenBox(value: EndOfInjectableType(), offset: offset, length: 1, line: .defaultLine)
        } else {
            return TokenBox(value: EndOfAnyDeclaration(), offset: offset, length: 1, line: .defaultLine)
        }
    }
}

private extension AccessLevel {

    init(_ stringValue: String) {
        switch stringValue {
        case "source.lang.swift.accessibility.internal":
            self = .internal
        case "source.lang.swift.accessibility.public":
            self = .public
        case "source.lang.swift.accessibility.open":
            self = .open
        default:
            self = .default
        }
    }
}

