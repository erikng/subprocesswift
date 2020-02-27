import SPMUtility
import Foundation


do {
  let parser = ArgumentParser(commandName: "subprocesswift",
                               usage: "--path '/path/to/tool' -a 'argument1' -a 'argument2'",
                               overview: "A tool to send binaries or scripts through a swift signed binary",
                               seeAlso: "getopt(1)")

  let input = parser.add(option: "--path",
                         shortName: "-p",
                         kind: String.self,
                         usage: "A path to the binary to run")


  let names = parser.add(option: "--arguments",
                         shortName: "-a",
                         kind: [String].self,
                         strategy: .oneByOne,
                         usage: "Any arguments for the selected binary",
                         completion: ShellCompletion.none)

  let argsv = Array(CommandLine.arguments.dropFirst())
  let parguments = try parser.parse(argsv)

  if let path = parguments.get(input) {
    if #available(macOS 10.13, *) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        if let multipleArguments = parguments.get(names) {
          task.arguments = multipleArguments
        }
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        try task.run()
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: outputData, as: UTF8.self)
        let error = String(decoding: errorData, as: UTF8.self)
        print(output, error)
    } else {
        print("macOS version below 10.13")
        exit(1)
    }
  } else {
    print("path not specified!")
    exit(1)
  }

} catch ArgumentParserError.expectedValue(let value) {
    print("Missing value for argument \(value).")
} catch ArgumentParserError.expectedArguments(let parser, let stringArray) {
    print("Parser: \(parser) Missing arguments: \(stringArray.joined()).")
} catch {
    print(error.localizedDescription)
}

