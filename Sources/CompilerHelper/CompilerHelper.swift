// The Swift Programming Language
// https://docs.swift.org/swift-book

/// Main description
@attached(peer, names: named(`CompilerFunction`))
public macro CompilerFunctionGenerator() = #externalMacro(module: "CompilerHelperMacros", type: "CompilerFunctionGeneratorMacro")
