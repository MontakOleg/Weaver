//
//  main.swift
//  WeaverCommand
//
//  Created by Théophane Rupin on 2/20/18.
//

import Foundation
import Commander
import WeaverCodeGen
import SourceKittenFramework
import Darwin
import PathKit
import Rainbow

private let version = "0.12.4"

// MARK: - Linker

private extension Linker {

    convenience init(_ inputPaths: [Path], shouldLog: Bool = true) throws {

        // ---- Parse ----

        if shouldLog {
            Logger.log(.info, "")
            Logger.log(.info, "Parsing...".yellow, benchmark: .start("parsing"))
        }
        let asts: [Expr] = try inputPaths.compactMap { filePath in
            guard let file = File(path: filePath.string) else {
                return nil
            }
            
            if shouldLog { Logger.log(.info, "<- '\(filePath)'".yellow) }
            let tokens = try Lexer(file, fileName: filePath.string).tokenize()
            return try Parser(tokens, fileName: filePath.string).parse()
        }
        if shouldLog { Logger.log(.info, "Done".yellow, benchmark: .end("parsing")) }

        // ---- Link ----
        
        
        if shouldLog {
            Logger.log(.info, "")
            Logger.log(.info, "Linking...".lightGreen, benchmark: .start("linking"))
        }
        try self.init(syntaxTrees: asts)
        if shouldLog { Logger.log(.info, "Done".lightGreen, benchmark: .end("linking")) }
    }
}

// MARK: - Parameters

private enum Parameters {
    static let projectPath = Option<Path?>("project-path", default: nil, description: "Project's directory.")
    static let configPath = Option<Path?>("config-path", default: nil, description: "Configuration path.")
    static let mainOutputPath = Option<Path?>("main-output-path", default: nil, description: "Where the main swift files will be generated.")
    static let testsOutputPath = Option<Path?>("tests-output-path", default: nil, description: "Where the tests swift files will be generated.")
    static let mainTemplatePath = Option<Path?>("main-template-path", default: nil, description: "Custom main template path.")
    static let detailedResolversTemplatePath = Option<Path?>("detailed-resolvers-template-path", default: nil, description: "Custom detailed resolvers template path.")
    static let unsafe = OptionalFlag("unsafe", disabledName: "safe")
    static let singleOutput = OptionalFlag("single-output", disabledName: "multi_outputs")
    static let inputPath = VariadicOption<String>("input-path", default: [], description: "Paths to input files.")
    static let ignoredPath = VariadicOption<String>("ignored-path", default: [], description: "Paths to ignore.")
    static let recursiveOff = OptionalFlag("recursive-off", disabledName: "recursive-on")
    static let pretty = Flag("pretty", default: false)
    static let detailedResolvers = OptionalFlag("detailed-resolvers", default: nil)
    static let tests = OptionalFlag("tests", default: nil)
    static let projectTargetName = Option<String?>("project-target-name", default: nil, description: "Project's target name.")
}

// MARK: - Commands

let main = Group {
    
    $0.command(
        "swift",
        Parameters.projectPath,
        Parameters.configPath,
        Parameters.mainOutputPath,
        Parameters.testsOutputPath,
        Parameters.mainTemplatePath,
        Parameters.detailedResolversTemplatePath,
        Parameters.unsafe,
        Parameters.detailedResolvers,
        Parameters.singleOutput,
        Parameters.inputPath,
        Parameters.ignoredPath,
        Parameters.recursiveOff,
        Parameters.tests,
        Parameters.projectTargetName)
    {
        projectPath,
        configPath,
        mainOutputPath,
        testsOutputPath,
        mainTemplatePath,
        detailedResolversTemplatePath,
        unsafe,
        detailedResolvers,
        singleOutput,
        inputPaths,
        ignoredPaths,
        recursiveOff,
        tests,
        projectTargetName in
        
        do {
            let configuration = try Configuration(configPath: configPath,
                                                  inputPathStrings: inputPaths.isEmpty ? nil : inputPaths,
                                                  ignoredPathStrings: ignoredPaths.isEmpty ? nil : ignoredPaths,
                                                  projectPath: projectPath,
                                                  mainOutputPath: mainOutputPath,
                                                  testsOutputPath: testsOutputPath,
                                                  mainTemplatePath: mainTemplatePath,
                                                  detailedResolversTemplatePath: detailedResolversTemplatePath,
                                                  unsafe: unsafe,
                                                  singleOutput: singleOutput,
                                                  recursiveOff: recursiveOff,
                                                  detailedResolvers: detailedResolvers,
                                                  tests: tests,
                                                  projectTargetName: projectTargetName)
            
            Logger.log(.info, "Let the injection begin.".lightRed, benchmark: .start("all"))

            // ---- Link ----

            let linker = try Linker(try configuration.inputPaths())
            let dependencyGraph = linker.dependencyGraph

            // ---- Generate ----

            Logger.log(.info, "")
            Logger.log(.info, "Generating boilerplate code...".lightBlue, benchmark: .start("generating"))

            let generator = try SwiftGenerator(dependencyGraph: dependencyGraph,
                                               detailedResolvers: configuration.detailedResolvers,
                                               version: version,
                                               mainTemplatePath: configuration.mainTemplatePath,
                                               detailedResolversTemplatePath: configuration.detailedResolversTemplatePath,
                                               testsTemplatePath: configuration.testsTemplatePath,
                                               macrosTemplatePath: configuration.macrosTemplatePath,
                                               projectTargetName: configuration.projectTargetName)

            let mainGeneratedData: [(file: String, data: String?)] = try {
                if configuration.singleOutput {
                    return [(file: "swift", data: try generator.generateMain())]
                } else {
                    return try generator.generateMain()
                }
            }()
            
            let testsGeneratedData: [(file: String, data: String?)] = try {
                if configuration.singleOutput {
                    return [(file: "swift", data: try generator.generateTests())]
                } else {
                    return try generator.generateTests()
                }
            }()

            Logger.log(.info, "Done".lightBlue, benchmark: .end("generating"))

            // ---- Collect ----

            let mainDataToWrite: [(path: Path, data: String?)] = mainGeneratedData.compactMap { (file, data) in

                let filePath = Path(file)

                guard let fileName = filePath.components.last else {
                    Logger.log(.error, "Could not retrieve file name from path '\(filePath)'".red)
                    return nil
                }
                let generatedFilePath = configuration.mainOutputPath + "Weaver.\(fileName)"

                guard let data = data else {
                    Logger.log(.info, "-- No Weaver annotation found in file '\(filePath)'.".red)
                    return (path: generatedFilePath, data: nil)
                }

                return (path: generatedFilePath, data: data)
            }
            
            let testsDataToWrite: [(path: Path, data: String?)] = configuration.tests ? testsGeneratedData.compactMap { (file, data) in
                
                let filePath = Path(file)
                
                guard let fileName = filePath.components.last else {
                    Logger.log(.error, "Could not retrieve file name from path '\(filePath)'".red)
                    return nil
                }
                let generatedFilePath = configuration.testsOutputPath + "WeaverTests.\(fileName)"
                
                guard let data = data else {
                    Logger.log(.info, "-- No Weaver annotation found in file '\(filePath)'.".red)
                    return (path: generatedFilePath, data: nil)
                }
                
                return (path: generatedFilePath, data: data)
            } : []

            // ---- Inspect ----

            if !configuration.unsafe {
                Logger.log(.info, "")
                Logger.log(.info, "Checking dependency graph...".magenta, benchmark: .start("checking"))

                let inspector = Inspector(dependencyGraph: dependencyGraph)
                try inspector.validate()

                Logger.log(.info, "Done".magenta, benchmark: .end("checking"))
            }

            // ---- Write ----

            Logger.log(.info, "")
            Logger.log(.info, "Writing...".lightMagenta, benchmark: .start("writing"))

            let dataToWrite = mainDataToWrite + testsDataToWrite
            for (path, data) in dataToWrite {
                if let data = data {
                    try path.parent().mkpath()
                    try path.write(data)
                    Logger.log(.info, "-> '\(path)'".lightMagenta)
                } else if path.isFile && path.isDeletable {
                    try path.parent().mkpath()
                    try path.delete()
                    Logger.log(.info, " X '\(path)'".lightMagenta)
                }
            }

            Logger.log(.info, "Done".lightMagenta, benchmark: .end("writing"))
            Logger.log(.info, "")
            Logger.log(.info, "Injection done in \(dependencyGraph.injectableTypesCount) different types".lightWhite, benchmark: .end("all"))
        } catch {
            Logger.log(.error, "\(error)")
            exit(1)
        }
    }
    
    $0.command(
        "json",
        Parameters.projectPath,
        Parameters.configPath,
        Parameters.pretty,
        Parameters.inputPath,
        Parameters.ignoredPath,
        Parameters.recursiveOff
    ) {
        projectPath,
        configPath,
        pretty,
        inputPaths,
        ignoredPaths,
        recursiveOff in
        
        let configuration = try Configuration(configPath: configPath,
                                              inputPathStrings: inputPaths.isEmpty ? nil : inputPaths,
                                              ignoredPathStrings: ignoredPaths.isEmpty ? nil : ignoredPaths,
                                              projectPath: projectPath,
                                              recursiveOff: recursiveOff)
        
        // ---- Link ----

        let linker = try Linker(try configuration.inputPaths(), shouldLog: false)
        let dependencyGraph = linker.dependencyGraph

        // ---- Export ----

        let encoder = JSONEncoder()
        if pretty {
            encoder.outputFormatting = .prettyPrinted
        }
        let jsonData = try encoder.encode(dependencyGraph)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            Logger.log(.error, "Could not generate json from data.")
            exit(1)
        }
        
        Logger.log(.info, jsonString)
    }
    
    $0.command(
        "xcfilelist",
        Parameters.configPath,
        Parameters.projectPath,
        Parameters.singleOutput,
        Parameters.inputPath,
        Parameters.ignoredPath,
        Parameters.recursiveOff
    ) {
        configPath,
        projectPath,
        singleOutput,
        inputPaths,
        ignoredPaths,
        recursiveOff in

        let configuration = try Configuration(configPath: configPath,
                                              inputPathStrings: inputPaths.isEmpty ? nil : inputPaths,
                                              ignoredPathStrings: ignoredPaths.isEmpty ? nil : ignoredPaths,
                                              projectPath: projectPath,
                                              singleOutput: singleOutput,
                                              recursiveOff: recursiveOff)

        // ---- Link ----

        let linker = try Linker(try configuration.inputPaths())
        let dependencyGraph = linker.dependencyGraph

        // ---- Write ----

        Logger.log(.info, "")
        Logger.log(.info, "Writing...".lightMagenta, benchmark: .start("writing"))

        let generator = XCFilelistGenerator(dependencyGraph: dependencyGraph,
                                            projectPath: configuration.projectPath,
                                            outputPath: configuration.mainOutputPath,
                                            singleOutput: configuration.singleOutput,
                                            version: version)

        let filelists = generator.generate()

        let inputFilelistPath = configuration.mainOutputPath + "WeaverInput.xcfilelist"
        try inputFilelistPath.parent().mkpath()
        try inputFilelistPath.write(filelists.input)
        Logger.log(.info, "-> \(inputFilelistPath)".lightMagenta)

        let outputFilelistPath = configuration.mainOutputPath + "WeaverOutput.xcfilelist"
        try outputFilelistPath.parent().mkpath()
        try outputFilelistPath.write(filelists.output)
        Logger.log(.info, "-> \(outputFilelistPath)".lightMagenta)

        Logger.log(.info, "Done".lightMagenta, benchmark: .end("writing"))
        Logger.log(.info, "")
    }
}

main.run(version)
