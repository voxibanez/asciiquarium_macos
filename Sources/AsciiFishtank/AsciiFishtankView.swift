// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (C) 2026 AsciiFishtank contributors
// Swift/macOS port derived from Asciiquarium v1.1 by Kirk Baucom.
// See NOTICE for original attribution and modification details.

import ScreenSaver
import AppKit
import QuartzCore
import SwiftUI
import OSLog

@objc(AsciiFishtankView)
public class AsciiFishtankView: ScreenSaverView {
    private var grid: GridRenderer?
    private var scene: AquariumScene?
    private var lastTickTime: CFTimeInterval = 0
    private var tickInterval: CFTimeInterval = 1.0 / 15.0
    private var sceneDirty: Bool = false
    
    private static let logger = Logger(subsystem: "com.asciifishtank.screensaver", category: "View")
    
    private var isAnimationRunning: Bool = false

    override public init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    deinit {
        Self.logger.info("AsciiFishtank: deinit called")
        DistributedNotificationCenter.default().removeObserver(self)
    }

    private func commonInit() {
        animationTimeInterval = 1.0 / AquariumConfig.baseTickRate
        
        let procName = ProcessInfo.processInfo.processName
        let myPid = ProcessInfo.processInfo.processIdentifier
        Self.logger.info("AsciiFishtank: commonInit. PID: \(myPid), Process: \(procName, privacy: .public), isPreview: \(self.isPreview)")
        
        setupTerminationObservers()
    }

    private func setupTerminationObservers() {
        // Only observe if not a preview, because preview mode stops naturally.
        guard !isPreview else { return }
        
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(self, selector: #selector(handleScreenSaverStopped), name: NSNotification.Name("com.apple.screensaver.didstop"), object: nil)
        dnc.addObserver(self, selector: #selector(handleScreenSaverStopped), name: NSNotification.Name("com.apple.screensaver.willstop"), object: nil)
        dnc.addObserver(self, selector: #selector(handleScreenSaverStopped), name: NSNotification.Name("com.apple.ScreenSaver.didStop"), object: nil)
    }

    @objc private func handleScreenSaverStopped() {
        Self.logger.info("AsciiFishtank: Received distributed stop notification. Stopping animation.")
        self.stopAnimation()
    }

    override public func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        Self.logger.info("AsciiFishtank: viewDidMoveToWindow: \(String(describing: self.window))")
    }

    override public func startAnimation() {
        Self.logger.info("AsciiFishtank: startAnimation")
        self.isAnimationRunning = true
        super.startAnimation()
        if grid == nil || scene == nil {
            setupScene()
        }
    }

    override public func stopAnimation() {
        Self.logger.info("AsciiFishtank: stopAnimation")
        self.isAnimationRunning = false
        super.stopAnimation()
        
        // Free up memory and CPU
        grid = nil
        scene = nil
        
        // Release all loaded ASCII art to drop memory footprint
        ArtRepository.free()
        
        // Release window backing store / VRAM
        self.layer?.contents = nil
        self.layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
    }

    override public func animateOneFrame() {
        // 0 CPU Usage when stopped. 
        // We DO NOT check window.isVisible here, because on Sonoma screensaver windows
        // are often reported as invisible or having no screen even when they are actively rendering!
        guard isAnimationRunning else { return }
        
        guard let scene = scene else { return }
        let now = CACurrentMediaTime()
        let elapsed = now - lastTickTime
        if elapsed > tickInterval * 10 {
            lastTickTime = now
            return
        }
        guard elapsed >= tickInterval else { return }
        lastTickTime += tickInterval
        scene.tick(dt: tickInterval)
        sceneDirty = true
        setNeedsDisplay(bounds)
    }

    override public func draw(_ rect: NSRect) {
        // 0 CPU Usage when stopped.
        guard isAnimationRunning else { return }
        
        guard let grid = grid, let scene = scene else { return }
        guard sceneDirty else { return }
        sceneDirty = false
        scene.render(into: grid)
        grid.render(dirtyRect: rect)
    }

    override public var hasConfigureSheet: Bool { true }

    override public var configureSheet: NSWindow? {
        let viewModel = SettingsViewModel()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 620),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = true

        let settingsView = AquariumSettingsView(
            viewModel: viewModel,
            onOK: { [weak self, weak window] in
                guard let win = window else { return }
                if let parent = win.sheetParent {
                    parent.endSheet(win, returnCode: .OK)
                } else {
                    win.close()
                }
                self?.setupScene()
            },
            onCancel: { [weak window] in
                guard let win = window else { return }
                if let parent = win.sheetParent {
                    parent.endSheet(win, returnCode: .cancel)
                } else {
                    win.close()
                }
            }
        )

        window.contentView = NSHostingView(rootView: settingsView)
        return window
    }

    private func setupScene() {
        let config = AquariumConfig.load()
        tickInterval = config.tickInterval
        animationTimeInterval = tickInterval
        let fontSize: CGFloat = isPreview ? 5.0 : CGFloat(config.fontSize)
        let g = GridRenderer(frame: bounds, fontSize: fontSize)
        let s = AquariumScene()
        s.setup(columns: g.columns, rows: g.rows, config: config)
        self.grid = g
        self.scene = s
        self.lastTickTime = CACurrentMediaTime()
        self.sceneDirty = true
    }
}
