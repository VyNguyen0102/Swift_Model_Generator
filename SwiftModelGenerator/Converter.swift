//
//  Converter.swift
//  SwiftModelGenerator
//
//  Created by Vy Nguyen on 11/26/18.
//  Copyright © 2018 VVLab. All rights reserved.
//

import Foundation
import SwiftyJSON

class Converter {
    static func convertStringToClass(jsonString: String) -> String {
        let json = JSON.init(parseJSON: jsonString)
        let keys = jsonString.JSONKeys
        var result = [StructModel]()
        result.append(contentsOf: convertDictionaryToStruct(modelKey: "Model", jsonKeys: keys, jsonValue: json))
        return result.reduce("", { $0 + $1.toString() })
    }
    static func convertDictionaryToStruct(modelKey: String, jsonKeys: [String], jsonValue: JSON) -> [StructModel] {
        var result = [StructModel]()
        var strucModel = StructModel.init(structName: modelKey.camelized.uppercasingFirst)
        jsonKeys.forEach { key in
            let value: JSON = jsonValue[key]
            if value.error != nil {
                return
            }
            switch value.type {
            case .number:
                if value.rawValue is Int {
                    print("\(value.description) is Int")
                    strucModel.variables.append((key,DataType.int))
                } else {
                    print("\(value.description) is Double")
                    strucModel.variables.append((key,DataType.double))
                }
            case .string:
                strucModel.variables.append((key,DataType.string))
            case .bool:
                strucModel.variables.append((key,DataType.bool))
            case .array:
                if let arrayValue = value.array,
                    let json = arrayValue.sorted(by: { (first, second) -> Bool in
                        first.count > second.count
                    }).first {
                    strucModel.variables.append((key, DataType.listOf(structName: key.singularize().uppercasingFirst)))
                    result.append(contentsOf: Converter.convertDictionaryToStruct(modelKey: key.singularize().uppercasingFirst, jsonKeys: jsonKeys, jsonValue: json))
                }
            case .dictionary:
                strucModel.structName = modelKey.camelized.uppercasingFirst
                strucModel.variables.append((key,DataType.typeStruct(structName: key)))
                result.append(contentsOf: Converter.convertDictionaryToStruct(modelKey: key.uppercasingFirst, jsonKeys: jsonKeys, jsonValue: value))

            default :
                strucModel.structName = modelKey.camelized.uppercasingFirst
                strucModel.variables.append((key, DataType.typeStruct(structName: key)))
            }
        }
        result.append(strucModel)
        return result
    }
}

enum DataType {
    case bool
    case string
    case int
    case double
    case listOf(structName: String)
    case typeStruct(structName: String)
    var name: String {
        switch self {
        case .bool:
            return "Bool"
        case .string:
            return "String"
        case .int:
            return "Int"
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
        case .int:
            return "0"
        case .double:
            return "0.0"
        case .listOf(_):
            return "[]"
        case .typeStruct(_):
            return "nil"
        }
    }
    var isOptional: Bool {
        if case .typeStruct(_) = self {
            return true
        }
        return false
    }
}

// Model
struct StructModel {
    var structName: String
    var variables: [(key: String, value: DataType)]
    init(structName: String) {
        self.structName = structName
        self.variables = [(key: String, value: DataType)]()
    }
    func toString() -> String {
        return "struct \(structName): Codable {\n"
            + variables.toVariablesString()
            
            + "\tprivate let Fields = (\n"
            + variables.toFields()
            + "\t)\n"
            
            + "\tinit("
            + variables.toInitParam()
            + ") {\n"
            + variables.toInitDeclareData()
            + "\t}\n"
            
            + "\tinit?(json: JSON) {\n"
            + variables.toInitDeclareDataFromJson()
            + "\t}\n"
            
            + "\tvar dictionary: [String: Any] {\n"
            + "\t\tvar dictionary:[String: Any] = [:]\n"
            + variables.toDictionaryString()
            + "\t\treturn dictionary\n"
            + "\t}\n"
            
            + "\tenum CodingKeys: String, CodingKey {\n"
            + variables.toKey()
            + "\t}\n"
            
            + "}\n\n"
    }
}
extension Array where Element == (key: String, value: DataType) {
    func toVariablesString() -> String {
        return reduce("", { $0 + "\tvar \($1.key.camelized): \($1.value.name)?\n"})
    }
    func toInitParam() -> String {
        return String(reduce("", { $0 + "\t\t\($1.key.camelized): \($1.value.name)?,\n"}).dropLast(2).dropFirst(2))
    }
    
    func toInitDeclareData() -> String {
        return reduce("", { $0 + "\t\tself.\($1.key.camelized) = \($1.key.camelized)\n"})
    }
    
    func toInitDeclareDataFromJson() -> String {
        return reduce("", { initialResult , nextPartialResult in
            let jsonValue: String = {
                if case DataType.typeStruct(structName: let name) = nextPartialResult.value {
                    return "\(nextPartialResult.value.name).init(json: json[Fields.\(nextPartialResult.key.camelized)])"
                } else {
                    return  "json[Fields.\(nextPartialResult.key.camelized)].\(nextPartialResult.value.name.lowercased())Value"
                }
            }()
            return initialResult + "\t\tself.\(nextPartialResult.key.camelized) = \(jsonValue)\n"
        })
    }
    
    func toDictionaryString() -> String {
        return reduce("", { $0 + "\t\tdictionary[Fields.\($1.key.camelized)] = self.\($1.key.camelized)\n"})
    }
    
    func toKey() -> String {
        return reduce("", { $0 + "\t\tcase \($1.key.camelized)\(String.createBlankBy(text: $1.key.camelized, numberOfMaxBlankSpace: 20))= \"\($1.key)\"\n"})
    }
    
    func toFields() -> String {
        return String(reduce("", { $0 + "\t\t \($1.key.camelized)\(String.createBlankBy(text: $1.key.camelized, numberOfMaxBlankSpace: 20)): \"\($1.key)\",\n"}).dropLast(2))
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

    func matches(for regex: String) -> [String] {

        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self,
                                        range: NSRange(self.startIndex..., in: self))
            return results.map {
                String(self[Range($0.range, in: self)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    // Keep order of json
    var JSONKeys: [String] {
        return self.matches(for: "(?!\")[A-z0-9-]+(?=\"\\s*:)").uniqued()
    }
}

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
