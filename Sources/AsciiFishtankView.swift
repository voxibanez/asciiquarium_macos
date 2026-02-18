import ScreenSaver
import AppKit
import QuartzCore

@objc(AsciiFishtankView)
public class AsciiFishtankView: ScreenSaverView {
    private var grid: GridRenderer?
    private var scene: AquariumScene?
    private var lastTickTime: CFTimeInterval = 0
    private var tickInterval: CFTimeInterval = 1.0 / 15.0  // seconds between simulation steps
    /// True only after a simulation tick has produced new state that hasn't been drawn yet.
    /// Prevents draw() from rendering stale state if the framework calls it more than once
    /// between ticks (e.g. due to window compositor redraws).
    private var sceneDirty: Bool = false

    // Keep the config controller and window alive for the lifetime of the view
    private lazy var configController: ConfigSheetController = ConfigSheetController()
    private lazy var configWindow: NSWindow = configController.makeWindow()

    override public init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / AquariumConfig.baseTickRate
        // macOS 26 (Tahoe): legacyScreenSaver.appex spawns a ghost instance with a
        // zero-size frame. Skip scene setup for ghost instances to avoid wasted work.
        if frame == .zero { return }
        setupScene()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        animationTimeInterval = 1.0 / AquariumConfig.baseTickRate
        setupScene()
    }

    private func setupScene() {
        let config = AquariumConfig.load()
        // Tick rate is driven by speedMultiplier alone.
        // stepSize controls the per-tick movement quantum, not tick frequency.
        tickInterval = config.tickInterval
        animationTimeInterval = tickInterval
        let fontSize: CGFloat = isPreview ? 5.0 : CGFloat(config.fontSize)
        let g = GridRenderer(frame: bounds, fontSize: fontSize)
        let s = AquariumScene()
        s.setup(columns: g.columns, rows: g.rows, config: config)
        self.grid = g
        self.scene = s
        self.lastTickTime = CACurrentMediaTime()
    }

    override public func animateOneFrame() {
        let now = CACurrentMediaTime()
        let elapsed = now - lastTickTime

        // Only tick the simulation when a full tick interval has elapsed.
        guard elapsed >= tickInterval else { return }

        // Phase-locked advance: always step lastTickTime by exactly tickInterval
        // rather than resetting to `now`. This prevents late-firing frames from
        // eating into the next interval — any scheduling slip is automatically
        // recovered on the next callback instead of compounding indefinitely.
        //
        // If we've fallen more than 4 intervals behind (e.g. after a system
        // stall), clamp to avoid a burst of catch-up ticks.
        let maxDrift = tickInterval * 4
        if elapsed > maxDrift {
            // Resync: we were stalled, just advance to now and move on.
            lastTickTime = now
        } else {
            lastTickTime += tickInterval
        }

        // dt is always exactly one tick interval for the simulation so entity
        // speeds are perfectly consistent regardless of when the OS fires us.
        scene?.tick(dt: tickInterval)
        sceneDirty = true
        setNeedsDisplay(bounds)
    }

    override public func draw(_ rect: NSRect) {
        guard let grid = grid, let scene = scene else { return }
        // Only render when the simulation has actually produced new state.
        // The framework can call draw() more than once between ticks (window
        // compositor redraws, etc.), which would otherwise show the same frame
        // twice and create the appearance of uneven pacing.
        guard sceneDirty else { return }
        sceneDirty = false
        scene.render(into: grid)
        grid.render(dirtyRect: rect)
    }

    override public var hasConfigureSheet: Bool { true }

    override public var configureSheet: NSWindow? {
        return configWindow
    }
}
