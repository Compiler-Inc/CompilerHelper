import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct CompilerHelperPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CompilerFunctionGeneratorMacro.self
    ]
}
