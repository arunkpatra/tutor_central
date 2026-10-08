// The sample pictures for the simulator's hand runs (it has no camera): a paper register page and two answer-sheet
// pages in a handwriting face, and a blank page under 1 KB (the local fake reads no names from it).
// Run once with `swift tools/samples/make.swift` from the repo root; the PNGs are committed.
import AppKit

let out = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "tools/samples")

func page(width: Int, height: Int, draw: (CGContext) -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = context
    let cg = context.cgContext
    cg.translateBy(x: 0, y: CGFloat(height))
    cg.scaleBy(x: 1, y: -1)
    draw(cg)
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func text(_ string: String, at point: CGPoint, size: CGFloat, ink: NSColor = NSColor(white: 0.12, alpha: 1)) {
    let font = NSFont(name: "Bradley Hand", size: size) ?? NSFont.systemFont(ofSize: size)
    let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: ink]
    let ns = NSAttributedString(string: string, attributes: attributes)
    NSGraphicsContext.current?.cgContext.saveGState()
    let cg = NSGraphicsContext.current!.cgContext
    cg.translateBy(x: point.x, y: point.y + size)
    cg.scaleBy(x: 1, y: -1)
    ns.draw(at: .zero)
    cg.restoreGState()
}

func paper(_ cg: CGContext, width: Int, height: Int) {
    cg.setFillColor(NSColor(red: 0.97, green: 0.95, blue: 0.9, alpha: 1).cgColor)
    cg.fill(CGRect(x: 0, y: 0, width: width, height: height))
}

func save(_ rep: NSBitmapImageRep, _ name: String) {
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: out.appendingPathComponent(name))
    print(name, data.count, "bytes")
}

let rows: [(String, String, String)] = [
    ("Aarav Mehta", "98765 43210", "1200"), ("Diya Pillai", "99887 76655", "1200"),
    ("Dev Kumar", "98848 43831", "1000"), ("Kavya Nair", "", "1200"), ("Rohan Gupta", "90080 11223", "1500"),
    ("Sneha Joshi", "98450 33221", "1200"), ("Ishaan Bose", "97400 55667", "1200"),
    ("Tanvi Kulkarni", "99000 44556", "1200"),
]

save(page(width: 1600, height: 1200) { cg in
    paper(cg, width: 1600, height: 1200)
    text("Bright Minds Tuition - Class 10 Maths - October", at: CGPoint(x: 80, y: 60), size: 44)
    let columns: [(String, CGFloat)] = [("No.", 80), ("Name", 200), ("Parent's phone", 720), ("Fee (Rs)", 1250)]
    for (title, x) in columns { text(title, at: CGPoint(x: x, y: 170), size: 36) }
    cg.setStrokeColor(NSColor(white: 0.45, alpha: 1).cgColor)
    cg.setLineWidth(2)
    for line in 0 ... 9 {
        let y = CGFloat(230 + line * 100)
        cg.move(to: CGPoint(x: 60, y: y)); cg.addLine(to: CGPoint(x: 1540, y: y))
    }
    cg.strokePath()
    for (index, row) in rows.enumerated() {
        let y = CGFloat(255 + index * 100)
        text("\(index + 1)", at: CGPoint(x: 90, y: y), size: 40)
        text(row.0, at: CGPoint(x: 200, y: y), size: 44)
        text(row.1, at: CGPoint(x: 720, y: y), size: 44)
        text(row.2, at: CGPoint(x: 1260, y: y), size: 44)
    }
}, "register-page.png")

let answers1 = [
    "Hemanth Reddy   Class 10 Maths   Quadratic equations",
    "1. (a) x^2 + 3 = 0", "2. D = b^2 - 4ac = 16 - 24 = -8", "3. 4 - 10 + k = 0 so k = 6",
    "4. roots are real and distinct", "5. (x - 3)(x - 4) = 0, x = 3 or x = 4",
    "6. D = 24 - 24 = 0, x = 2 root6 / 6", "7.",
]
let answers2 = [
    "8. x = (-1 +- root 49) / 4, x = 3/2 or x = -2",
    "9. 360/x - 360/(x+5) = 1", "   x^2 + 5x - 1800 = 0", "   (x + 45)(x - 40) = 0 so speed = 45 km/h",
    "10. x(x + 2) = 195", "    x^2 + 2x - 195 = 0", "    (x + 15)(x - 13) = 0", "    numbers are 13 and 15",
]
for (name, lines) in [("answer-sheet-1.png", answers1), ("answer-sheet-2.png", answers2)] {
    save(page(width: 1200, height: 1600) { cg in
        paper(cg, width: 1200, height: 1600)
        cg.setStrokeColor(NSColor(red: 0.7, green: 0.78, blue: 0.9, alpha: 1).cgColor)
        cg.setLineWidth(2)
        for line in 0 ... 14 {
            let y = CGFloat(140 + line * 95)
            cg.move(to: CGPoint(x: 40, y: y)); cg.addLine(to: CGPoint(x: 1160, y: y))
        }
        cg.strokePath()
        for (index, line) in lines.enumerated() {
            text(line, at: CGPoint(x: 70, y: CGFloat(80 + index * 140)), size: 46, ink: NSColor(red: 0.1, green: 0.15, blue: 0.45, alpha: 1))
        }
    }, name)
}

save(page(width: 64, height: 64) { cg in paper(cg, width: 64, height: 64) }, "blank.png")
