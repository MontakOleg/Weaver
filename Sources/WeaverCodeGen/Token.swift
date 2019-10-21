//
//  Token.swift
//  WeaverCodeGen
//
//  Created by Théophane Rupin on 2/22/18.
//

import Foundation
import SourceKittenFramework

// MARK: - Token

public protocol AnyTokenBox {
    var offset: Int { get }
    var length: Int { get }
    var line: Int { get set }
}

public struct TokenBox<T: Token & Hashable>: AnyTokenBox, Hashable, CustomStringConvertible {
    let value: T
    public let offset: Int
    public let length: Int
    public var line: Int
    
    public var description: String {
        return "\(value) - \(offset)[\(length)] - at line: \(line)"
    }
}

public protocol Token: CustomStringConvertible {
    static func create(_ string: String) throws -> Self?
}

// MARK: - Token SwiftTypes

public struct RegisterAnnotation: Token, Hashable {

    let name: String
    let type: SwiftType
    let protocolType: SwiftType?
    
    public static func create(_ string: String) throws -> RegisterAnnotation? {
        guard let matches = try NSRegularExpression(pattern: Patterns.register).matches(in: string) else {
            return nil
        }

        let protocolType: SwiftType?
        let arrowIndex = matches.firstIndex { $0.hasPrefix("<-") }
        if let arrowIndex = arrowIndex, arrowIndex + 1 < matches.count {
            protocolType = try SwiftType(matches[arrowIndex + 1])
        } else {
            protocolType = nil
        }
        
        guard let type = try SwiftType(matches[1]) else {
            return nil
        }
        
        return RegisterAnnotation(name: matches[0], type: type, protocolType: protocolType)
    }
    
    public var description: String {
        var s = "\(name) = \(type)"
        if let protocolType = protocolType {
            s += " <- \(protocolType)"
        }
        return s
    }
}

public struct ReferenceAnnotation: Token, Hashable {
    
    let name: String
    let type: SwiftType
    
    public static func create(_ string: String) throws -> ReferenceAnnotation? {
        guard let matches = try NSRegularExpression(pattern: Patterns.reference).matches(in: string) else {
            return nil
        }
        guard let type = try SwiftType(matches[1]) else {
            return nil
        }
        return ReferenceAnnotation(name: matches[0], type: type)
    }
    
    public var description: String {
        return "\(name) <- \(type)"
    }
}

public struct ParameterAnnotation: Token, Hashable {
    
    let name: String
    let type: SwiftType
    
    public static func create(_ string: String) throws -> ParameterAnnotation? {
        guard let matches = try NSRegularExpression(pattern: Patterns.parameter).matches(in: string) else {
            return nil
        }
        guard let type = try SwiftType(matches[1]) else {
            return nil
        }
        return ParameterAnnotation(name: matches[0], type: type)
    }
    
    public var description: String {
        return "\(name) <= \(type)"
    }
}

public struct ConfigurationAnnotation: Token, Hashable {
    
    let attribute: ConfigurationAttribute
    
    let target: ConfigurationAttributeTarget
    
    struct UniqueIdentifier: Hashable, Equatable {
        let name: ConfigurationAttributeName
        let target: ConfigurationAttributeTarget
    }

    var uniqueIdentifier: UniqueIdentifier {
        return UniqueIdentifier(name: attribute.name, target: target)
    }
    
    public static func create(_ string: String) throws -> ConfigurationAnnotation? {
        guard let matches = try NSRegularExpression(pattern: Patterns.configuration).matches(in: string) else {
            return nil
        }
        
        let target = ConfigurationAttributeTarget(matches[0])
        let attribute = try ConfigurationAttribute(name: matches[1], valueString: matches[2])
        
        guard validate(configurationAttribute: attribute, with: target) else {
            throw TokenError.invalidConfigurationAttributeTarget(name: attribute.name.rawValue, target: target)
        }
        
        return ConfigurationAnnotation(attribute: attribute, target: target)
    }
    
    public var description: String {
        return "\(target).\(attribute)"
    }
}

public struct ImportDeclaration: Token, Hashable {
    
    let moduleName: String
    
    public static func create(_ string: String) throws -> ImportDeclaration? {
        guard let matches = try NSRegularExpression(pattern: Patterns.import).matches(in: string) else {
            return nil
        }
        
        return ImportDeclaration(moduleName: matches[0])
    }
    
    public var description: String {
        return "import \(moduleName)"
    }
}

public struct InjectableType: Token, Hashable {
    let type: SwiftType
    let accessLevel: AccessLevel
    let doesSupportObjc: Bool

    init(type: SwiftType,
         accessLevel: AccessLevel = .default,
         doesSupportObjc: Bool = false) {
        self.type = type
        self.accessLevel = accessLevel
        self.doesSupportObjc = doesSupportObjc
    }
    
    public var description: String {
        return "\(accessLevel.rawValue) \(type) {"
    }
}

public struct EndOfInjectableType: Token, Hashable {
    public let description = "_ }"
}

public struct AnyDeclaration: Token, Hashable {
    public let description = "{"
}

public struct EndOfAnyDeclaration: Token, Hashable {
    public let description = "}"
}

// MARK: - Annotation Builder

enum TokenBuilder {

    static func makeAnnotationToken(string: String,
                                    offset: Int,
                                    length: Int,
                                    line: Int) throws -> AnyTokenBox? {
        
        let chars = CharacterSet(charactersIn: "/").union(.whitespaces)
        let annotation = string.trimmingCharacters(in: chars)

        let bodyRegex = try NSRegularExpression(pattern: "^weaver\\s*:\\s*(.*)")
        guard let body = bodyRegex.matches(in: annotation)?.first else {
            return nil
        }

        func makeTokenBox<T: Token & Equatable & Hashable>(_ token: T) -> AnyTokenBox {
            return TokenBox(value: token, offset: offset, length: length, line: line)
        }
        
        if let token = try ConfigurationAnnotation.create(body) {
            return makeTokenBox(token)
        }
        if let token = try RegisterAnnotation.create(body) {
            return makeTokenBox(token)
        }
        if let token = try ReferenceAnnotation.create(body) {
            return makeTokenBox(token)
        }
        if let token = try ParameterAnnotation.create(body) {
            return makeTokenBox(token)
        }
        if let token = try ImportDeclaration.create(body) {
            return makeTokenBox(token)
        }
        throw TokenError.invalidAnnotation(annotation)
    }
}

// MARK: - Default implementations

extension Token {
    public static func create(_ string: String) throws -> Self? {
        return nil
    }
}

