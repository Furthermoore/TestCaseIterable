import TestCaseIterable

@TestCaseIterable
struct MyStruct {
    let one: Bool
    let two: Bool
    let three: Bool
}

extension MyStruct: CustomStringConvertible {
    var description: String {
        return "(\(one), \(two), \(three))"
    }
}

print(MyStruct.allCases)
