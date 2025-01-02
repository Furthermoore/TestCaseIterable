import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(TestCaseIterableMacros)
import TestCaseIterableMacros

let testMacros: [String: Macro.Type] = [
    "TestCaseIterable": TestCaseIterableMacro.self,
]
#endif

final class TestCaseIterableTests: XCTestCase {
    
    func testCaseIterableMacroSimpleUsage() throws {
    #if canImport(TestCaseIterableMacros)
        assertMacroExpansion(
            """
            @TestCaseIterable
            struct MyStruct {
                let first: Bool
                let second: Bool
            }
            """,
            expandedSource:
            """
            struct MyStruct {
                let first: Bool
                let second: Bool
            }

            extension MyStruct: CaseIterable {
                static var allCases: [Self] {
                    [
                        Self(first: true, second: true),
                        Self(first: true, second: false),
                        Self(first: false, second: true),
                        Self(first: false, second: false)
                    ]
                }
            }
            """,
            macros: testMacros)
    #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
    }
}
