//
//  Converter.swift
//  SwiftModelGenerator
//
//  Created by Vy Nguyen on 11/26/18.
//  Copyright © 2018 VVLab. All rights reserved.
//

import Foundation

class Converter {
    static func convertStringToClass(json: String) -> String {
        guard let dic = json.dictionary else {
            return ""
        }
        var result = [StructModel]()
        result.append(contentsOf: convertDictionaryToStruct(key: "Model", value: dic))
        return result.reduce("", { $0 + $1.toString() })
    }
    static func convertDictionaryToStruct(key: String, value: Any?) -> [StructModel] {
        var result = [StructModel]()
        var strucModel = StructModel.init(structName: key.singularize().camelized.uppercasingFirst)
        if let value = value as? [String: Any] {
            value.forEach { (key, value) in
                if value is String {
                    strucModel.variables[key] = DataType.string
                } else if value is Bool {
                    strucModel.variables[key] = DataType.bool
                } else if value is Double {
                    strucModel.variables[key] = DataType.double
                } else if value is [String: Any] {
                    strucModel.variables[key] = DataType.typeStruct(structName: key)
                    result.append(contentsOf: Converter.convertDictionaryToStruct(key: key, value: value as! [String: Any]))
                } else if value is [Any] {
                    strucModel.variables[key] = DataType.listOf(structName: key.singularize().uppercasingFirst)
                    result.append(contentsOf: Converter.convertDictionaryToStruct(key: key, value: (value as! [Any]).first))
                } else { // Nil will default declare by Model
                    strucModel.variables[key] = DataType.typeStruct(structName: key)
                }
            }
            result.append(strucModel)
        }
        return result
    }
}

enum DataType {
    case bool
    case string
    case double
    case listOf(structName: String)
    case typeStruct(structName: String)
    var name: String {
        switch self {
        case .bool:
            return "Bool"
        case .string:
            return "String"
        case .double:
            return "Double"
        case .listOf(let structName):
            return "[\(structName)]"
        case .typeStruct(let structName):
            return structName.camelized.uppercasingFirst
        }
    }
    var defaultValue: String {
        switch self {
        case .bool:
            return "false"
        case .string:
            return "\"\""
        case .double:
            return "0.0"
        case .listOf(_):
            return "[]"
        case .typeStruct(_):
            return "nil"
        }
    }

}

// Model
struct StructModel {
    var structName: String
    var variables: [String: DataType]
    init(structName: String) {
        self.structName = structName
        self.variables = [String: DataType]()
    }
    func toString() -> String {
        return "struct \(structName) : Mappable {\n"
            + variables.toString()
            + "\tinit(map: Mapper) {\n"
            + variables.toMaping()
            + "\t}\n"
            + "}\n"
    }
}
extension Sequence where Iterator.Element == (key: String, value: DataType) {
    func toString() -> String {
        return reduce("", { $0 + "\tvar \($1.key.camelized): \($1.value.name)\n"})
    }
    func toMaping() -> String {
        return reduce("", { $0 + "\t\t\($1.key.camelized)\t\t= map.optionalFrom(\"\($1.key)\") ?? \($1.value.defaultValue)\n"})
    }
}
extension String {
    var dictionary: [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}

fileprivate let badChars = CharacterSet.alphanumerics.inverted

extension String {
    var uppercasingFirst: String {
        return prefix(1).uppercased() + dropFirst()
    }

    var lowercasingFirst: String {
        return prefix(1).lowercased() + dropFirst()
    }

    var camelized: String {
        guard !isEmpty else {
            return ""
        }

        let parts = self.components(separatedBy: badChars)

        let first = String(describing: parts.first!).lowercasingFirst
        let rest = parts.dropFirst().map({String($0).uppercasingFirst})

        return ([first] + rest).joined(separator: "")
    }
}
