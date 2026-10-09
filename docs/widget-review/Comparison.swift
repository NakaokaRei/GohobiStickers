import AppKit
let args = CommandLine.arguments
let paths = Array(args.dropFirst(2))
let width: CGFloat = 1092
let cellHeight: CGFloat = 590
let output = NSImage(size: NSSize(width: width, height: cellHeight * CGFloat(paths.count)))
output.lockFocus()
NSColor.white.setFill(); NSRect(origin: .zero, size: output.size).fill()
for (index, path) in paths.enumerated() {
 let image = NSImage(contentsOfFile: path)!
 let imageHeight = width * image.size.height / image.size.width
 let y = cellHeight * CGFloat(paths.count - index - 1)
 image.draw(in: NSRect(x: 0, y: y, width: width, height: imageHeight))
 (URL(fileURLWithPath: path).lastPathComponent as NSString).draw(at: NSPoint(x: 10, y: y+imageHeight+4), withAttributes: [.font: NSFont.systemFont(ofSize: 20), .foregroundColor: NSColor.black])
}
output.unlockFocus()
let rep = NSBitmapImageRep(data: output.tiffRepresentation!)!
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[1]))
