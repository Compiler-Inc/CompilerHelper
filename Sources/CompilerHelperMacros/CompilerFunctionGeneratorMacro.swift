import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum CompilerFunctionGeneratorError: CustomStringConvertible, Error {
    case onlyApplicableToEnum

    public var description: String {
        switch self {
        case .onlyApplicableToEnum:
            "@AddAsync can only be applied to an enumeration."
       }
    }
}

public struct CompilerFunctionGeneratorMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax,
                                 providingPeersOf declaration: some DeclSyntaxProtocol,
                                 in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard let mainEnum = declaration.as(EnumDeclSyntax.self) else {
            throw CompilerFunctionGeneratorError.onlyApplicableToEnum
        }
        
        func upperFirst(_ text: String) -> String {
            text.first!.uppercased() + text.dropFirst()
        }
 
        let members = mainEnum.memberBlock.members
        let caseDecls = members.compactMap({ $0.decl.as(EnumCaseDeclSyntax.self) })
        let elements = caseDecls.flatMap( { $0.elements })

        let typeCases = elements.map { "case \($0.name)" }.joined(separator: "\n")
        let cases = elements.map { "case \($0.name)(Function<\(upperFirst($0.name.text))Parameters>)" }.joined(separator: "\n")
        
        var structsText = ""
        
        for element in elements {
            structsText.append("struct \(upperFirst(element.name.text))Parameters: Decodable, Sendable {\n")
            if let clause = element.parameterClause {
                for parameter in clause.parameters {
                    if let f = parameter.firstName {
                        structsText.append("let \(f): \(parameter.type) \n")
                    }
                }
            }
            structsText.append("}")
        }
        
        var initCases = ""
        for element in elements {
            initCases.append("case .\(element.name):\n")
            if let clause = element.parameterClause {
                initCases.append("let params = try container.decodeIfPresent(\(upperFirst(element.name.text))Parameters.self, forKey: .parameters) ?? nil\n")
                initCases.append("self = .\(element.name)(.init(id: functionType.rawValue, parameters: params, colloquialResponse: colloquialResp))\n")
            } else {
                initCases.append("self = .\(element.name)(.init(id: functionType.rawValue, parameters: \(upperFirst(element.name.text))Parameters(), colloquialResponse: colloquialResp))\n")
            }
        }
        initCases.append("\n")
        
        let colloquialCases = elements.map { "case .\($0.name)(let f):\n\treturn f.colloquialResponse" }.joined(separator: "\n")

        
        return [DeclSyntax(stringLiteral: """
                enum CompilerFunction: Decodable, Sendable {
                    private enum CodingKeys: String, CodingKey {
                        case function
                        case parameters
                        case colloquialResponse = "colloquial_response"
                    }
                
                    private enum FunctionType: String, Decodable {
                        \(typeCases)
                    }
                
                    \(cases)
                    \(structsText)
                
                    public init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        let functionType = try container.decode(FunctionType.self, forKey: .function)
                        let colloquialResp = try container.decodeIfPresent(String.self, forKey: .colloquialResponse) ?? "Processing metronome command"
                        
                        switch functionType {
                            \(initCases)
                        }
                    }
                    
                    var colloquialResponse: String {
                        switch self {
                            \(colloquialCases)
                        }
                    }
                
                }
                
                """)]
     }
}
