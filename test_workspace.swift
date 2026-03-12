import Foundation
import AppKit
import UniformTypeIdentifiers

if #available(macOS 12.0, *) {
    let ws = NSWorkspace.shared
    let url = URL(fileURLWithPath: "/Applications/md.app")
    let type = UTType("net.daringfireball.markdown")!

    ws.setDefaultApplication(at: url, toOpen: type) { error in
        guard let error else { return }
        FileHandle.standardError.write(Data("\(error.localizedDescription)\n".utf8))
    }
}
