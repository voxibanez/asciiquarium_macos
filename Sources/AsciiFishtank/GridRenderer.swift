import AppKit
import OSLog

private let logger = Logger(subsystem: "com.asciifishtank.screensaver", category: "Grid")

struct Cell {
    var character: Character = " "
    var colorIndex: UInt16 = 0
    var bold: Bool = false
    var xOffset: CGFloat = 0
}

class GridRenderer {
    let columns: Int
    let rows: Int

    deinit {
        logger.info("AsciiFishtank: GridRenderer deallocated")
    }

    let font: NSFont
    let boldFont: NSFont
    let cellWidth: CGFloat
    let cellHeight: CGFloat
    let originX: CGFloat
    let originY: CGFloat
    let frameWidth: CGFloat
    let frameHeight: CGFloat

    private var palette: [NSColor] = []
    private var paletteIndex: [ObjectIdentifier: UInt16] = [:]

    private struct AttrKey: Hashable {
        let colorIndex: UInt16; let bold: Bool
    }
    private var attrCache: [AttrKey: [NSAttributedString.Key: Any]] = [:]

    private let backgroundCGColor: CGColor
    private var rowBaselines: [CGFloat]
    private var flatCells: [Cell]

    // Cache for pre-rendered lines (runs of characters).
    // Keyed by the string content, color, bold state, and quantized xOffset.
    private struct RunKey: Hashable {
        let text: String
        let colorIndex: UInt16
        let bold: Bool
        let quantizedOffset: Int // Offset in 0.25px units
    }
    private var runCache: [RunKey: CTLine] = [:]
    private let maxCacheSize = 2000

    init(frame: NSRect, fontSize: CGFloat) {
        let baseFont = NSFont(name: "Menlo", size: fontSize)
            ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        let baseBoldFont = NSFont(name: "Menlo-Bold", size: fontSize)
            ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)

        self.font = baseFont
        self.boldFont = baseBoldFont

        let attrs: [NSAttributedString.Key: Any] = [.font: baseFont]
        let measure = NSAttributedString(string: "M", attributes: attrs)
        let size = measure.size()
        let naturalWidth = size.width
        self.cellHeight = ceil(size.height)

        let cols = max(1, Int(frame.width / naturalWidth))
        self.columns = cols
        self.cellWidth = frame.width / CGFloat(cols)
        self.rows = max(1, Int(frame.height / cellHeight))

        self.originX = 0
        self.originY = frame.height - CGFloat(rows) * cellHeight
        self.frameWidth = frame.width
        self.frameHeight = frame.height
        self.backgroundCGColor = ColorPalette.background.cgColor

        let ascent = baseFont.ascender
        let descender = baseFont.descender
        var baselines = [CGFloat](repeating: 0, count: rows)
        for row in 0..<rows {
            let cellTop = originY + CGFloat(rows - 1 - row) * cellHeight
            baselines[row] = cellTop + (cellHeight - ascent) * 0.5 - descender * 0.3
        }
        self.rowBaselines = baselines

        let totalCells = columns * rows
        self.flatCells = [Cell](repeating: Cell(), count: totalCells)

        _ = colorIndex(for: .white)
    }

    func colorIndex(for color: NSColor) -> UInt16 {
        let id = ObjectIdentifier(color)
        if let idx = paletteIndex[id] { return idx }
        let idx = UInt16(palette.count)
        palette.append(color)
        paletteIndex[id] = idx
        return idx
    }

    func colAndOffset(for x: Double) -> (col: Int, offset: CGFloat) {
        let col = Int(x)
        let frac = x - Double(col)
        return (col, CGFloat(frac) * cellWidth)
    }

    func clear() {
        let empty = Cell()
        flatCells.withUnsafeMutableBufferPointer { buf in
            for i in buf.indices { buf[i] = empty }
        }
    }

    func putChar(_ ch: Character, at col: Int, row: Int, foreground: NSColor, bold: Bool = false, xOffset: CGFloat = 0) {
        guard row >= 0 && row < rows && col >= 0 && col < columns else { return }
        let idx = colorIndex(for: foreground)
        let cell = Cell(character: ch, colorIndex: idx, bold: bold, xOffset: xOffset)
        flatCells[row * columns + col] = cell
    }

    func putString(_ s: String, at col: Int, row: Int, foreground: NSColor, bold: Bool = false, transparent: Bool = true, xOffset: CGFloat = 0) {
        guard row >= 0 && row < rows else { return }
        let idx = colorIndex(for: foreground)
        var c = col
        for ch in s {
            if c >= 0 && c < columns {
                if !transparent || ch != " " {
                    let cell = Cell(character: ch, colorIndex: idx, bold: bold, xOffset: xOffset)
                    flatCells[row * columns + c] = cell
                }
            }
            c += 1
        }
    }

    func putMultilineArt(_ lines: [String], at col: Int, row: Int, foreground: NSColor, bold: Bool = false, transparent: Bool = true) {
        for (i, line) in lines.enumerated() {
            putString(line, at: col, row: row + i, foreground: foreground, bold: bold, transparent: transparent)
        }
    }

    func render(dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        ctx.setFillColor(backgroundCGColor)
        ctx.fill(CGRect(x: 0, y: 0, width: frameWidth, height: frameHeight))

        // Simple cache eviction if it grows too large
        if runCache.count > maxCacheSize {
            runCache.removeAll(keepingCapacity: true)
        }

        autoreleasepool {
            for row in 0..<rows {
                let baseline = rowBaselines[row]
                var col = 0
                
                while col < columns {
                    let cell = flatCells[row * columns + col]
                    if cell.character == " " {
                        col += 1
                        continue
                    }

                    let startCol = col
                    let colorIdx = cell.colorIndex
                    let isBold = cell.bold
                    let xOff = cell.xOffset
                    
                    var runText = String(cell.character)
                    col += 1
                    
                    while col < columns {
                        let next = flatCells[row * columns + col]
                        if next.character != " " && next.colorIndex == colorIdx && next.bold == isBold && next.xOffset == xOff {
                            runText.append(next.character)
                            col += 1
                        } else {
                            break
                        }
                    }
                    
                    // Quantize xOffset to 0.25px units to allow cache hits while keeping movement smooth
                    let qOffset = Int((xOff * 4.0).rounded())
                    let key = RunKey(text: runText, colorIndex: colorIdx, bold: isBold, quantizedOffset: qOffset)
                    
                    let line: CTLine
                    if let cached = runCache[key] {
                        line = cached
                    } else {
                        let color = palette[Int(colorIdx)]
                        let attrKey = AttrKey(colorIndex: colorIdx, bold: isBold)
                        let attrs = cachedAttrs(key: attrKey, color: color, bold: isBold)
                        let astr = CFAttributedStringCreate(nil, runText as CFString, attrs as CFDictionary)!
                        line = CTLineCreateWithAttributedString(astr)
                        runCache[key] = line
                    }
                    
                    let x = originX + CGFloat(startCol) * cellWidth + (CGFloat(qOffset) / 4.0)
                    ctx.textPosition = CGPoint(x: x, y: baseline)
                    CTLineDraw(line, ctx)
                }
            }
        }
    }

    private func cachedAttrs(key: AttrKey, color: NSColor, bold: Bool) -> [NSAttributedString.Key: Any] {
        if let cached = attrCache[key] { return cached }
        let attrs: [NSAttributedString.Key: Any] = [
            .font: bold ? boldFont : font,
            .foregroundColor: color
        ]
        attrCache[key] = attrs
        return attrs
    }
}
