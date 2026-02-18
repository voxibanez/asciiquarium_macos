import AppKit

// Pack character + color index + bold + xOffset into a struct.
// Color is stored as an index into a small palette rather than an NSColor reference,
// eliminating per-cell color-space conversions in the hot render path.
struct Cell {
    var character: Character = " "
    var colorIndex: UInt16 = 0     // index into GridRenderer.palette
    var bold: Bool = false
    /// Sub-cell horizontal pixel offset for smooth movement.
    var xOffset: CGFloat = 0
}

class GridRenderer {
    let columns: Int
    let rows: Int
    var cells: [[Cell]]

    let font: NSFont
    let boldFont: NSFont
    let cellWidth: CGFloat
    let cellHeight: CGFloat
    let originX: CGFloat
    let originY: CGFloat
    let frameWidth: CGFloat
    let frameHeight: CGFloat

    // Color palette: NSColor objects indexed by UInt16.
    // Avoids repeated getRed:green:blue: conversions in the hot render path.
    private var palette: [NSColor] = []
    private var paletteIndex: [ObjectIdentifier: UInt16] = [:]

    // Pre-built attribute dictionaries keyed by (colorIndex, bold).
    private struct AttrKey: Hashable {
        let colorIndex: UInt16; let bold: Bool
    }
    private var attrCache: [AttrKey: [NSAttributedString.Key: Any]] = [:]

    // CGColor cache for the background fill (avoids repeated bridging).
    private let backgroundCGColor: CGColor

    // Pre-computed per-row baseline Y values (constant after init).
    private var rowBaselines: [CGFloat]

    // Flat cells buffer for cache-friendly iteration.
    // cells[row][col] == flatCells[row * columns + col]
    private var flatCells: [Cell]

    init(frame: NSRect, fontSize: CGFloat) {
        let baseFont = NSFont(name: "Menlo", size: fontSize)
            ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        let baseBoldFont = NSFont(name: "Menlo-Bold", size: fontSize)
            ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)

        self.font = baseFont
        self.boldFont = baseBoldFont

        // Measure natural cell size
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
        let gridHeight = CGFloat(rows) * cellHeight
        self.originY = frame.height - gridHeight

        self.frameWidth = frame.width
        self.frameHeight = frame.height

        self.backgroundCGColor = ColorPalette.background.cgColor

        // Pre-compute per-row baseline Y values once.
        let ascent = baseFont.ascender
        let descender = baseFont.descender
        let r = max(1, Int(frame.height / ceil(size.height)))
        var baselines = [CGFloat](repeating: 0, count: r)
        let oy = frame.height - CGFloat(r) * ceil(size.height)
        for row in 0..<r {
            let cellTop = oy + CGFloat(r - 1 - row) * ceil(size.height)
            baselines[row] = cellTop + (ceil(size.height) - ascent) * 0.5 - descender * 0.3
        }
        self.rowBaselines = baselines

        let totalCells = cols * max(1, Int(frame.height / cellHeight))
        self.flatCells = [Cell](repeating: Cell(), count: totalCells)
        self.cells = Array(repeating: Array(repeating: Cell(), count: cols),
                           count: max(1, Int(frame.height / cellHeight)))

        // Pre-register the white color (most common) as index 0.
        _ = colorIndex(for: .white)
    }

    // MARK: - Color palette management

    /// Returns (or creates) a stable index for the given NSColor.
    /// Colors are deduplicated by pointer identity — callers must use shared
    /// static NSColor instances (as ColorPalette does) for maximum reuse.
    func colorIndex(for color: NSColor) -> UInt16 {
        let id = ObjectIdentifier(color)
        if let idx = paletteIndex[id] { return idx }
        let idx = UInt16(palette.count)
        palette.append(color)
        paletteIndex[id] = idx
        return idx
    }

    // MARK: - Sub-cell offset helper

    /// Converts a continuous column position into an integer grid column and a
    /// pixel offset in [0, cellWidth). Using floor (not round) keeps the offset
    /// always non-negative, eliminating the half-cell pop that `rounded()` causes
    /// when the fractional part crosses 0.5.
    func colAndOffset(for x: Double) -> (col: Int, offset: CGFloat) {
        let col = Int(x)                     // floor — always the column to the left
        let frac = x - Double(col)           // always in [0, 1)
        return (col, CGFloat(frac) * cellWidth)
    }

    // MARK: - Grid population

    func clear() {
        let empty = Cell()
        // Use withUnsafeMutableBufferPointer for a single-pass flat reset.
        flatCells.withUnsafeMutableBufferPointer { buf in
            for i in buf.indices { buf[i] = empty }
        }
        // Keep cells 2-D array in sync (used by putChar/putString callers).
        // We mirror writes from flat buffer — resync here once per frame.
        // Since we always clear then repopulate, just zero the 2-D array too.
        let emptyRow = Array(repeating: empty, count: columns)
        for r in 0..<rows { cells[r] = emptyRow }
    }

    func putChar(_ ch: Character, at col: Int, row: Int, foreground: NSColor, bold: Bool = false) {
        guard row >= 0 && row < rows && col >= 0 && col < columns else { return }
        let idx = colorIndex(for: foreground)
        let cell = Cell(character: ch, colorIndex: idx, bold: bold, xOffset: 0)
        cells[row][col] = cell
        flatCells[row &* columns &+ col] = cell
    }

    func putChar(_ ch: Character, at col: Int, row: Int, foreground: NSColor, bold: Bool = false, xOffset: CGFloat) {
        guard row >= 0 && row < rows && col >= 0 && col < columns else { return }
        let idx = colorIndex(for: foreground)
        let cell = Cell(character: ch, colorIndex: idx, bold: bold, xOffset: xOffset)
        cells[row][col] = cell
        flatCells[row &* columns &+ col] = cell
    }

    func putString(_ s: String, at col: Int, row: Int, foreground: NSColor, bold: Bool = false, transparent: Bool = true) {
        guard row >= 0 && row < rows else { return }
        let idx = colorIndex(for: foreground)
        var c = col
        for ch in s {
            if c >= 0 && c < columns {
                if !transparent || ch != " " {
                    let cell = Cell(character: ch, colorIndex: idx, bold: bold, xOffset: 0)
                    cells[row][c] = cell
                    flatCells[row &* columns &+ c] = cell
                }
            }
            c &+= 1
        }
    }

    func putString(_ s: String, at col: Int, row: Int, foreground: NSColor, bold: Bool = false, transparent: Bool = true, xOffset: CGFloat) {
        guard row >= 0 && row < rows else { return }
        let idx = colorIndex(for: foreground)
        var c = col
        for ch in s {
            if c >= 0 && c < columns {
                if !transparent || ch != " " {
                    let cell = Cell(character: ch, colorIndex: idx, bold: bold, xOffset: xOffset)
                    cells[row][c] = cell
                    flatCells[row &* columns &+ c] = cell
                }
            }
            c &+= 1
        }
    }

    func putMultilineArt(_ lines: [String], at col: Int, row: Int, foreground: NSColor, bold: Bool = false, transparent: Bool = true) {
        let idx = colorIndex(for: foreground)
        for (i, line) in lines.enumerated() {
            let r = row + i
            guard r >= 0 && r < rows else { continue }
            var c = col
            for ch in line {
                if c >= 0 && c < columns {
                    if !transparent || ch != " " {
                        let cell = Cell(character: ch, colorIndex: idx, bold: bold, xOffset: 0)
                        cells[r][c] = cell
                        flatCells[r &* columns &+ c] = cell
                    }
                }
                c &+= 1
            }
        }
    }

    // MARK: - Rendering

    // Cache CTLine per (scalar, colorIndex, bold) — CTLine is lightweight and reusable.
    private struct GlyphKey: Hashable {
        let scalar: Unicode.Scalar
        let colorIndex: UInt16
        let bold: Bool
    }
    private var glyphCache: [GlyphKey: CTLine] = [:]

    func render(dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        // Always clear the entire frame, not just dirtyRect.
        // Clearing only dirtyRect leaves ghost pixels from xOffset sub-cell motion
        // (a glyph drawn at col+offset last frame won't be erased if that cell
        // isn't in the next dirty rect).
        ctx.setFillColor(backgroundCGColor)
        ctx.fill(CGRect(x: 0, y: 0, width: frameWidth, height: frameHeight))

        // Iterate flat buffer for better cache locality.
        var flatIdx = 0
        for row in 0..<rows {
            let baseline = rowBaselines[row]

            for col in 0..<columns {
                let cell = flatCells[flatIdx]
                flatIdx &+= 1

                guard cell.character != " ", let scalar = cell.character.unicodeScalars.first else { continue }

                let x = originX + CGFloat(col) * cellWidth + cell.xOffset

                let glyphKey = GlyphKey(scalar: scalar, colorIndex: cell.colorIndex, bold: cell.bold)

                let line: CTLine
                if let cached = glyphCache[glyphKey] {
                    line = cached
                } else {
                    let color = palette[Int(cell.colorIndex)]
                    let attrKey = AttrKey(colorIndex: cell.colorIndex, bold: cell.bold)
                    let attrs = cachedAttrs(key: attrKey, color: color, bold: cell.bold)
                    let astr = CFAttributedStringCreate(nil, String(scalar) as CFString, attrs as CFDictionary)!
                    line = CTLineCreateWithAttributedString(astr)
                    glyphCache[glyphKey] = line
                }

                ctx.textPosition = CGPoint(x: x, y: baseline)
                CTLineDraw(line, ctx)
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
