import Foundation
import EW4NativeCore

func eprint(_ message: String) {
    FileHandle.standardError.write(Data(message.utf8))
}

let args = CommandLine.arguments
guard args.count >= 2 else {
    eprint("usage: EW4NativeAudit <Resources-root>\n")
    exit(2)
}

do {
    let report = try NativeResourceAuditor.audit(resourceRoot: URL(fileURLWithPath: args[1]))
    let out = try JSONEncoder().encode(report)
    print(String(decoding: out, as: UTF8.self))
    exit(report.passed ? 0 : 1)
} catch {
    eprint("audit failed: \(error)\n")
    exit(1)
}
