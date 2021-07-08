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
        var result = [StructModel]()
        result.append(contentsOf: convertDictionaryToStruct(modelKey: "Model", jsonValue: json))
        return result.reduce("", { $0 + $1.toString() })
    }
    static func convertDictionaryToStruct(modelKey: String, jsonValue: JSON) -> [StructModel] {
        var result = [StructModel]()
        var strucModel = StructModel.init(structName: modelKey.camelized.uppercasingFirst)
        if let jsonValue = jsonValue.dictionary {
            jsonValue.forEach { (key, value) in
                switch value.type {
                case .number:
                    if value.rawValue is Int {
                        print("\(value.description) is Int")
                        strucModel.variables[key] = DataType.int
                    } else {
                        print("\(value.description) is Double")
                        strucModel.variables[key] = DataType.double
                    }
                case .string:
                    strucModel.variables[key] = DataType.string
                case .bool:
                    strucModel.variables[key] = DataType.bool
                case .array:
                    if let arrayValue = value.array,
                        let json = arrayValue.sorted(by: { (first, second) -> Bool in
                            first.count > second.count
                        }).first {
                        strucModel.variables[key] = DataType.listOf(structName: key.singularize().uppercasingFirst)
                        result.append(contentsOf: Converter.convertDictionaryToStruct(modelKey: key.singularize().uppercasingFirst, jsonValue: json))
                    }
                case .dictionary:
                    strucModel.structName = modelKey.camelized.uppercasingFirst
                    strucModel.variables[key] = DataType.typeStruct(structName: key)
                    result.append(contentsOf: Converter.convertDictionaryToStruct(modelKey: key.uppercasingFirst, jsonValue: value))
                default :
                    strucModel.structName = modelKey.camelized.uppercasingFirst
                    strucModel.variables[key] = DataType.typeStruct(structName: key)
                }
            }
            result.append(strucModel)
        }
        return result
//        if let value = value as? [String: Any] {
//            value.forEach { (key, value) in
//                if value is String {
//                    strucModel.variables[key] = DataType.string
//                } else if value is Bool {
//                    strucModel.variables[key] = DataType.bool
//                } else if value is Double {
//                    if value is Int {
//                        strucModel.variables[key] = DataType.int
//                    } else {
//                        strucModel.variables[key] = DataType.double
//                    }
//                }  else if value is [String: Any] {
//                    strucModel.structName = modelKey.camelized.uppercasingFirst
//                    strucModel.variables[key] = DataType.typeStruct(structName: key)
//                    result.append(contentsOf: Converter.convertDictionaryToStruct(modelKey: key.uppercasingFirst, value: value as! [String: Any]))
//                } else if value is [Any] {
//                    strucModel.variables[key] = DataType.listOf(structName: key.singularize().uppercasingFirst)
//                    result.append(contentsOf: Converter.convertDictionaryToStruct(modelKey: key.singularize().uppercasingFirst, value: (value as! [Any]).first))
//                } else { // Nil will default declare by Model
//                    strucModel.structName = modelKey.camelized.uppercasingFirst
//                    strucModel.variables[key] = DataType.typeStruct(structName: key)
//                }
//            }
//            result.append(strucModel)
//        }
        
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
    var variables: [String: DataType]
    init(structName: String) {
        self.structName = structName
        self.variables = [String: DataType]()
    }
    func toString() -> String {
        return "struct \(structName): Codable {\n"
            + variables.sorted( by: {$0.key < $1.key}).toString()
            
            + "\tinit("
            + variables.sorted( by: {$0.key < $1.key}).toInitParam()
            + ") {\n"
            + variables.sorted( by: {$0.key < $1.key}).toInitDeclareData()
            + "\t}\n"
            
            + "\tinit?(json: JSON) {\n"
            + variables.sorted( by: {$0.key < $1.key}).toInitDeclareDataFromJson()
            + "\t}\n"
            
            + "\tvar dictionary: [String: Any] {\n"
            + "\t\tvar dictionary:[String: Any] = [:]\n"
            + variables.sorted( by: {$0.key < $1.key}).toDictionaryString()
            + "\t\treturn dictionary\n"
            + "\t}\n"
            + "\tenum CodingKeys: String, CodingKey {\n"
            + variables.sorted( by: {$0.key < $1.key}).toKey()
            + "\t}\n"
            + "}\n\n"
    }
}
extension Sequence where Iterator.Element == (key: String, value: DataType) {
    func toString() -> String {
        return reduce("", { $0 + "\tvar \($1.key.camelized): \($1.value.name)?\n"})
    }
    func toInitParam() -> String {
        return String(reduce("", { $0 + "\t\t\($1.key.camelized): \($1.value.name)?,\n"}).dropLast(2).dropFirst(2))
    }
    
    func toInitDeclareData() -> String {
        return reduce("", { $0 + "\t\tself.\($1.key.camelized) = \($1.key.camelized)\n"})
    }
    
    func toInitDeclareDataFromJson() -> String {
        return reduce("", { $0 + "\t\tself.\($1.key.camelized) = json[\"\($1.key)\"].\($1.value.name.lowercased())Value\n"})
    }
    
    func toDictionaryString() -> String {
        return reduce("", { $0 + "\t\tdictionary[\"\($1.key)\"] = self.\($1.key.camelized)\n"})
    }
    
    func toKey() -> String {
        return reduce("", { $0 + "\t\tcase \($1.key.camelized)\(String.createBlankBy(text: $1.key.camelized, numberOfMaxBlankSpace: 20))= \"\($1.key)\"\n"})
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
