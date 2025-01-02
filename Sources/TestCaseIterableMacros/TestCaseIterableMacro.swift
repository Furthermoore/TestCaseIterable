import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `TestCaseIterable` macro, which takes a simple struct
/// declaration and produces a `CaseIterable` conformance, intended for use with
/// the `@Test` macro's `arguments` parameter.
///
/// ```swift
/// @TestCaseIterable
/// struct TestConfig {
///     let first: Bool
///     let second: Bool
/// }
/// ```
///
///  will expand to
///
/// ```swift
/// extension TestConfig: CaseIterable {
///     static var allCases: [TestConfig] {
///         [
///             TestConfig(first: true, second: true),
///             TestConfig(first: true, second: false),
///             TestConfig(first: false, second: true),
///             TestConfig(first: false, second: false)
///         ]
///     }
/// }
/// ```
///
public struct TestCaseIterableMacro: ExtensionMacro {
    
    enum Error: Swift.Error, CustomStringConvertible {
        case requiresStructType
        case requiresOnlyVariables
        case defaultValuesNotAllowed
        case computedValuesNotAllowed
        case requiresIdentifierPattern
        case requiresTypeAnnotation
        case typeError
        
        var description: String {
            switch self {
            case .requiresStructType:
                return "@TestCaseIterable only works on struct types"
            case .requiresOnlyVariables:
                return "@TestCaseIterable structs may only contain 'let' vars"
            case .defaultValuesNotAllowed:
                return "@TestCaseIterable struct members may not contain default values"
            case .computedValuesNotAllowed:
                return "@TestCaseIterable struct members may not contain computed variables"
            case .requiresTypeAnnotation:
                return "@TestCaseIterable struct members require type annotation"
            case .requiresIdentifierPattern:
                return "@TestCaseIterable struct members require identifier pattern (tuples not allowed)"
            case .typeError:
                return "Type Error"
            }
        }
    }
    
    public static func expansion (
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw Error.requiresStructType
        }
        
        var names = [String]()

        for member in structDecl.memberBlock.members {
            guard let variableDecl = member.decl.as(VariableDeclSyntax.self),
                  variableDecl.bindingSpecifier.text == "let"
            else {
                throw Error.requiresOnlyVariables
            }
            
            
            for binding in variableDecl.bindings {
                guard let typeAnnotation = binding.typeAnnotation,
                      binding.initializer == nil else {
                    throw Error.defaultValuesNotAllowed
                }
                guard binding.accessorBlock == nil else {
                    throw Error.computedValuesNotAllowed
                }
                guard let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                    throw Error.requiresIdentifierPattern
                }
                let variableName = identifierPattern.identifier.text
                names.append(variableName)
                
                guard let typeIdentifier = typeAnnotation.type.as(IdentifierTypeSyntax.self) else {
                    throw Error.typeError
                }
                guard typeIdentifier.name.text == "Bool" else {
                    throw Error.typeError
                }
            }
            
        }
        
        typealias Member = (name: String, possibleValues: [String])
        var members: [Member] = []
        for name in names {
            members.append((name, ["true", "false"]))
        }
        
        let combinations = generateCombinations(members.map(\.possibleValues))
        
        var initializerStrings = ""
        for (i, combo) in combinations.enumerated() {
            var initializerString = "Self("
            for (j, member) in members.enumerated() {
                initializerString.append("\(member.name): \(combo[j])")
                if j < members.count - 1 {
                    initializerString.append(", ")
                }
            }
            initializerString.append(")")
            if i < combinations.count - 1 {
                initializerString.append(",\n")
            }
            initializerStrings.append(initializerString)
        }
        
        return [try ExtensionDeclSyntax (
            """
            extension \(type.trimmed): CaseIterable {
                static var allCases: [Self] {
                    [
                        \(raw: initializerStrings)
                    ]
                }
            }
            """
        )]
    }
    
    private static func generateCombinations (
        _ inputs: [[String]]
    ) -> [[String]] {
        guard !inputs.isEmpty else { return [] }
        
        // Helper function for recursion
        func combine (
            _ current: [String],
            _ remaining: [[String]]
        ) -> [[String]] {
            guard !remaining.isEmpty else { return [current] }
            
            var results = [[String]]()
            let first = remaining[0]
            let rest = Array(remaining.dropFirst())
            
            for item in first {
                results += combine(current + [item], rest)
            }
            
            return results
        }
        
        return combine([], inputs)
    }
    
}



@main
struct TestCaseIterablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        TestCaseIterableMacro.self,
    ]
}
