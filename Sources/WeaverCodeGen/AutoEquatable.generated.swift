// Generated using Sourcery 0.13.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable file_length
fileprivate func compareOptionals<T>(lhs: T?, rhs: T?, compare: (_ lhs: T, _ rhs: T) -> Bool) -> Bool {
    switch (lhs, rhs) {
    case let (lValue?, rValue?):
        return compare(lValue, rValue)
    case (nil, nil):
        return true
    default:
        return false
    }
}

fileprivate func compareArrays<T>(lhs: [T], rhs: [T], compare: (_ lhs: T, _ rhs: T) -> Bool) -> Bool {
    guard lhs.count == rhs.count else { return false }
    for (idx, lhsItem) in lhs.enumerated() {
        guard compare(lhsItem, rhs[idx]) else { return false }
    }

    return true
}


// MARK: - AutoEquatable for classes, protocols, structs
// MARK: - AnyDeclaration AutoEquatable
extension AnyDeclaration: Equatable {}
public func == (lhs: AnyDeclaration, rhs: AnyDeclaration) -> Bool {
    guard lhs.description == rhs.description else { return false }
    return true
}
// MARK: - ConfigurationAnnotation AutoEquatable
extension ConfigurationAnnotation: Equatable {}
public func == (lhs: ConfigurationAnnotation, rhs: ConfigurationAnnotation) -> Bool {
    guard lhs.attribute == rhs.attribute else { return false }
    return true
}
// MARK: - CustomRefAnnotation AutoEquatable
extension CustomRefAnnotation: Equatable {}
public func == (lhs: CustomRefAnnotation, rhs: CustomRefAnnotation) -> Bool {
    guard lhs.name == rhs.name else { return false }
    guard lhs.value == rhs.value else { return false }
    return true
}
// MARK: - EndOfAnyDeclaration AutoEquatable
extension EndOfAnyDeclaration: Equatable {}
public func == (lhs: EndOfAnyDeclaration, rhs: EndOfAnyDeclaration) -> Bool {
    guard lhs.description == rhs.description else { return false }
    return true
}
// MARK: - EndOfInjectableType AutoEquatable
extension EndOfInjectableType: Equatable {}
public func == (lhs: EndOfInjectableType, rhs: EndOfInjectableType) -> Bool {
    guard lhs.description == rhs.description else { return false }
    return true
}
// MARK: - InjectableType AutoEquatable
extension InjectableType: Equatable {}
public func == (lhs: InjectableType, rhs: InjectableType) -> Bool {
    guard lhs.name == rhs.name else { return false }
    guard lhs.accessLevel == rhs.accessLevel else { return false }
    guard lhs.doesSupportObjc == rhs.doesSupportObjc else { return false }
    return true
}
// MARK: - ParameterAnnotation AutoEquatable
extension ParameterAnnotation: Equatable {}
public func == (lhs: ParameterAnnotation, rhs: ParameterAnnotation) -> Bool {
    guard lhs.name == rhs.name else { return false }
    guard lhs.typeName == rhs.typeName else { return false }
    return true
}
// MARK: - ReferenceAnnotation AutoEquatable
extension ReferenceAnnotation: Equatable {}
public func == (lhs: ReferenceAnnotation, rhs: ReferenceAnnotation) -> Bool {
    guard lhs.name == rhs.name else { return false }
    guard lhs.typeName == rhs.typeName else { return false }
    return true
}
// MARK: - RegisterAnnotation AutoEquatable
extension RegisterAnnotation: Equatable {}
public func == (lhs: RegisterAnnotation, rhs: RegisterAnnotation) -> Bool {
    guard lhs.name == rhs.name else { return false }
    guard lhs.typeName == rhs.typeName else { return false }
    guard compareOptionals(lhs: lhs.protocolName, rhs: rhs.protocolName, compare: ==) else { return false }
    return true
}
// MARK: - ScopeAnnotation AutoEquatable
extension ScopeAnnotation: Equatable {}
public func == (lhs: ScopeAnnotation, rhs: ScopeAnnotation) -> Bool {
    guard lhs.name == rhs.name else { return false }
    guard lhs.scope == rhs.scope else { return false }
    return true
}
// MARK: - Token AutoEquatable
public func == (lhs: Token, rhs: Token) -> Bool {
    return true
}

// MARK: - AutoEquatable for Enums
// MARK: - ConfigurationAttribute AutoEquatable
extension ConfigurationAttribute: Equatable {}
internal func == (lhs: ConfigurationAttribute, rhs: ConfigurationAttribute) -> Bool {
    switch (lhs, rhs) {
    case (.isIsolated(let lhs), .isIsolated(let rhs)):
        return lhs == rhs
    }
}
// MARK: - Expr AutoEquatable
extension Expr: Equatable {}
public func == (lhs: Expr, rhs: Expr) -> Bool {
    switch (lhs, rhs) {
    case (.file(let lhs), .file(let rhs)):
        if lhs.types != rhs.types { return false }
        if lhs.name != rhs.name { return false }
        return true
    case (.typeDeclaration(let lhs), .typeDeclaration(let rhs)):
        if lhs.0 != rhs.0 { return false }
        if lhs.config != rhs.config { return false }
        if lhs.children != rhs.children { return false }
        return true
    case (.registerAnnotation(let lhs), .registerAnnotation(let rhs)):
        return lhs == rhs
    case (.scopeAnnotation(let lhs), .scopeAnnotation(let rhs)):
        return lhs == rhs
    case (.referenceAnnotation(let lhs), .referenceAnnotation(let rhs)):
        return lhs == rhs
    case (.customRefAnnotation(let lhs), .customRefAnnotation(let rhs)):
        return lhs == rhs
    case (.parameterAnnotation(let lhs), .parameterAnnotation(let rhs)):
        return lhs == rhs
    default: return false
    }
}
// MARK: - GeneratorError AutoEquatable
extension GeneratorError: Equatable {}
internal func == (lhs: GeneratorError, rhs: GeneratorError) -> Bool {
    switch (lhs, rhs) {
    case (.invalidTemplatePath(let lhs), .invalidTemplatePath(let rhs)):
        return lhs == rhs
    }
}
// MARK: - InspectorAnalysisError AutoEquatable
extension InspectorAnalysisError: Equatable {}
internal func == (lhs: InspectorAnalysisError, rhs: InspectorAnalysisError) -> Bool {
    switch (lhs, rhs) {
    case (.cyclicDependency, .cyclicDependency):
        return true
    case (.unresolvableDependency, .unresolvableDependency):
        return true
    case (.isolatedResolverCannotHaveReferents, .isolatedResolverCannotHaveReferents):
        return true
    default: return false
    }
}
// MARK: - InspectorError AutoEquatable
extension InspectorError: Equatable {}
internal func == (lhs: InspectorError, rhs: InspectorError) -> Bool {
    switch (lhs, rhs) {
    case (.invalidAST(let lhs), .invalidAST(let rhs)):
        if lhs.unexpectedExpr != rhs.unexpectedExpr { return false }
        if lhs.file != rhs.file { return false }
        return true
    case (.invalidGraph(let lhs), .invalidGraph(let rhs)):
        if lhs.line != rhs.line { return false }
        if lhs.file != rhs.file { return false }
        if lhs.dependencyName != rhs.dependencyName { return false }
        if lhs.typeName != rhs.typeName { return false }
        if lhs.underlyingError != rhs.underlyingError { return false }
        return true
    default: return false
    }
}
// MARK: - LexerError AutoEquatable
extension LexerError: Equatable {}
internal func == (lhs: LexerError, rhs: LexerError) -> Bool {
    switch (lhs, rhs) {
    case (.invalidAnnotation(let lhs), .invalidAnnotation(let rhs)):
        if lhs.line != rhs.line { return false }
        if lhs.file != rhs.file { return false }
        if lhs.underlyingError != rhs.underlyingError { return false }
        return true
    }
}
// MARK: - ParserError AutoEquatable
extension ParserError: Equatable {}
internal func == (lhs: ParserError, rhs: ParserError) -> Bool {
    switch (lhs, rhs) {
    case (.unexpectedToken(let lhs), .unexpectedToken(let rhs)):
        if lhs.line != rhs.line { return false }
        if lhs.file != rhs.file { return false }
        return true
    case (.unexpectedEOF(let lhs), .unexpectedEOF(let rhs)):
        return lhs == rhs
    case (.unknownDependency(let lhs), .unknownDependency(let rhs)):
        if lhs.line != rhs.line { return false }
        if lhs.file != rhs.file { return false }
        if lhs.dependencyName != rhs.dependencyName { return false }
        return true
    case (.depedencyDoubleDeclaration(let lhs), .depedencyDoubleDeclaration(let rhs)):
        if lhs.line != rhs.line { return false }
        if lhs.file != rhs.file { return false }
        if lhs.dependencyName != rhs.dependencyName { return false }
        return true
    case (.configurationAttributeDoubleAssignation(let lhs), .configurationAttributeDoubleAssignation(let rhs)):
        if lhs.line != rhs.line { return false }
        if lhs.file != rhs.file { return false }
        if lhs.attribute != rhs.attribute { return false }
        return true
    default: return false
    }
}
// MARK: - TokenError AutoEquatable
extension TokenError: Equatable {}
internal func == (lhs: TokenError, rhs: TokenError) -> Bool {
    switch (lhs, rhs) {
    case (.invalidAnnotation(let lhs), .invalidAnnotation(let rhs)):
        return lhs == rhs
    case (.invalidScope(let lhs), .invalidScope(let rhs)):
        return lhs == rhs
    case (.invalidCustomRefValue(let lhs), .invalidCustomRefValue(let rhs)):
        return lhs == rhs
    case (.invalidConfigurationAttributeValue(let lhs), .invalidConfigurationAttributeValue(let rhs)):
        if lhs.value != rhs.value { return false }
        if lhs.expected != rhs.expected { return false }
        return true
    default: return false
    }
}