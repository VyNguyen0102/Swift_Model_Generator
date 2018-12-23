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
        let result = convertDictionaryToStruct(key: "YourModel", value: dic)
        return result.reduce("", { $0 + $1.toString() })
    }
    static func convertDictionaryToStruct(key: String, value: Any) -> [StructModel] {
        if let value = value as? [String: Any] {
            var result = [StructModel]()
            var strucModel = StructModel.init(structName: key.camelized.uppercasingFirst)
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
                }
            }
            result.append(strucModel)
            return result
        } else {
            return []
        }
    }
}

enum DataType {
    case bool
    case string
    case double
    case typeStruct(structName: String)
    var name: String {
        switch self {
        case .bool:
            return "Bool"
        case .string:
            return "String"
        case .double:
            return "Double"
        case .typeStruct(let structName):
            return structName.camelized.uppercasingFirst
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
        return "struct \(structName) {\n"
            + variables.toString()
            + "\tfunc mapping(map: Map) {\n"
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
        return reduce("", { $0 + "\t\t\($1.key.camelized)\t\t<- map[\"\($1.key)\"]\n"})
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
