//
//  TXT2XML.swift
//  swift-txt-to-xml
//
//  Created by Jia-Han Wu on 2024/10/03.
//

import ArgumentParser
import Foundation

@main
struct TXT2XML: ParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "txt2xml",
        abstract: "A utility for converting text files to XML format.",
        version: "0.0.1"
    )
    
    @Argument(help: "The input file or directory path to convert to XML.")
    var inputPath: String
    
    @Option(name: .shortAndLong, help: "Comma-separated list of file extensions to process (e.g., 'txt,md,swift'). If not specified, all files will be processed.")
    var types: String?
    
    @Flag(name: .shortAndLong, help: "Recursively process subdirectories when the input is a directory.")
    var recursive = false
    
    @Flag(name: .long, help: "Include hidden files when processing directories.")
    var includeHidden = false
    
    @Flag(name: .long, help: "Trim whitespace and newlines from the beginning and end of the content.")
    var trim = false
    
    @Option(name: .shortAndLong, help: "The output file path. If not specified, output will be printed to stdout.")
    var outputPath: String?
    
    func run() throws {
        let inputURL = URL(filePath: inputPath)
        
        let fileManager = FileManager.default
        
        var isDirectory: ObjCBool = false
        
        guard fileManager.fileExists(atPath: inputURL.path(), isDirectory: &isDirectory) else {
            throw NSError()
        }
        
        if isDirectory.boolValue {
            guard let enumerator = fileManager.enumerator(
                at: inputURL,
                includingPropertiesForKeys: nil,
                options: includeHidden ? [] : [.skipsHiddenFiles]
            ) else {
                throw NSError()
            }
            
            let allowedFileExtension = types?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            
            var index = 0
            
            var output = """
            <documents>
            
            """
            
            while let url = enumerator.nextObject() as? URL {
                if !recursive && url.pathComponents.count > inputURL.pathComponents.count + 1 {
                    continue
                }
                
                let fileExtension = url.pathExtension.lowercased()
                
                guard !fileExtension.isEmpty else {
                    continue
                }
                
                if let allowedFileExtension, !allowedFileExtension.contains(fileExtension) {
                    continue
                }
                
                let content = try getContent(at: url)
                
                output += """
                <document index="\(index)">
                <source>\(url.path())</source>
                <document_content>
                \(content)
                </document_content>
                </document>
                
                """
                
                index += 1
            }
            
            output += "</documents>"
            
            try processOutput(output)
        } else {
            let content = try getContent(at: inputURL)
            
            let output = """
             <document>
             <source>\(inputURL.path())</source>
             <document_content>
             \(content)
             </document_content>
             </document>
            """
            
            try processOutput(output)
        }
    }
    
    private func getContent(at url: URL) throws -> String {
        var content = try String(contentsOf: url, encoding: .utf8)
        
        if trim {
            content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return content
    }
    
    private func processOutput(_ output: String) throws {
        if let outputPath {
            try output.write(toFile: outputPath, atomically: true, encoding: .utf8)
        } else {
            print(output)
        }
    }
    
}
