/// This macro improves both the capability and readability of parameterized tests when using
/// the SwiftTesting framework. It automatically conforms simple struct types to
/// CaseIterable, with an implementation of `allCases` that returns all possible values
/// your type could represent, or a configurable range of values when appropriate.
/// This allows for generating as many test cases as you'd like.
/// ```swift
/// @TestCaseIterable
/// struct Struct {
///     let first: Bool
///     let second: Bool
/// }
/// ```
///
/// generates the following `CaseIterable` conformance:
///
/// ```swift
/// extension SomeStruct: CaseIterable {
///     static var allCases: [SomeStruct] {
///         SomeStruct(first: true, second: true),
///         SomeStruct(first: true, second: false),
///         SomeStruct(first: false, second: true),
///         SomeStruct(first: false, second: false)
///     }
/// }
/// ```
///
/// **NOTE:** *Currently only supports structs with `Bool` members.*
@attached(extension,
          names: named(allCases),
          conformances: CaseIterable)
public macro TestCaseIterable (
//    _ nameAndPossibilitiesDict: [String: [String]]? = nil
) = #externalMacro(module: "TestCaseIterableMacros",
                   type: "TestCaseIterableMacro")
