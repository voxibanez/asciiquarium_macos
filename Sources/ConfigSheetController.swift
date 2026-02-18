import AppKit
import ScreenSaver

class ConfigSheetController {
    private var window: NSWindow!
    private var config: AquariumConfig
    private var scrollView: NSScrollView!
    private var mainStack: NSStackView!
    private var sectionContents: [NSButton: NSView] = [:]  // disclosure button -> content view

    // MARK: - Control references

    // Display
    private var fpsSlider: NSSlider!
    private var fpsValueLabel: NSTextField!
    private var fontSizeSlider: NSSlider!
    private var fontSizeValueLabel: NSTextField!
    private var showBorderCheckbox: NSButton!

    // Speed
    private var speedSlider: NSSlider!
    private var speedValueLabel: NSTextField!
    private var staggeredMovementCheckbox: NSButton!

    // Fish
    private var fishDensitySlider: NSSlider!
    private var fishDensityValueLabel: NSTextField!
    private var schoolIntervalSlider: NSSlider!
    private var schoolIntervalValueLabel: NSTextField!

    // Bubbles
    private var bubbleSlider: NSSlider!
    private var bubbleValueLabel: NSTextField!
    private var fishBubbleSlider: NSSlider!
    private var fishBubbleValueLabel: NSTextField!

    // Creatures
    private var crabSlider: NSSlider!
    private var crabValueLabel: NSTextField!
    private var jellyfishSlider: NSSlider!
    private var jellyfishValueLabel: NSTextField!
    private var jellyfishCheckbox: NSButton!
    private var seaweedSlider: NSSlider!
    private var seaweedValueLabel: NSTextField!
    private var treasureCheckbox: NSButton!

    // Rare events
    private var sharkIntervalSlider: NSSlider!
    private var sharkIntervalValueLabel: NSTextField!
    private var sharksCheckbox: NSButton!
    private var whaleIntervalSlider: NSSlider!
    private var whaleIntervalValueLabel: NSTextField!
    private var whalesCheckbox: NSButton!
    private var monsterIntervalSlider: NSSlider!
    private var monsterIntervalValueLabel: NSTextField!
    private var monstersCheckbox: NSButton!
    private var shipIntervalSlider: NSSlider!
    private var shipIntervalValueLabel: NSTextField!
    private var shipsCheckbox: NSButton!

    init() {
        self.config = AquariumConfig.load()
    }

    // MARK: - Window Construction

    func makeWindow() -> NSWindow {
        let windowWidth: CGFloat = 500
        let windowHeight: CGFloat = 620

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "ASCII Fishtank"
        window.isReleasedWhenClosed = false
        window.level = .floating

        let root = NSView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))
        window.contentView = root

        // --- Title area ---
        let titleLabel = makeLabel("><((('>  ASCII Fishtank  <')))><", bold: true, size: 15)
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(titleLabel)

        let subtitle = makeLabel("Settings are applied on next screensaver launch.", size: 10)
        subtitle.alignment = .center
        subtitle.textColor = .secondaryLabelColor
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(subtitle)

        // --- Scroll view with all sections ---
        scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        root.addSubview(scrollView)

        mainStack = NSStackView()
        mainStack.orientation = .vertical
        mainStack.alignment = .leading
        mainStack.spacing = 2
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        // Flip the document view so stack grows downward
        let flipView = FlippedView()
        flipView.translatesAutoresizingMaskIntoConstraints = false
        flipView.addSubview(mainStack)
        scrollView.documentView = flipView

        // Build sections
        buildDisplaySection()
        buildAnimationSection()
        buildFishSection()
        buildBubblesSection()
        buildCreaturesSection()
        buildRareEventsSection()

        // --- Button bar ---
        let buttonBar = NSView()
        buttonBar.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(buttonBar)

        let sep = NSBox()
        sep.boxType = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(sep)

        let okButton = NSButton(title: "OK", target: self, action: #selector(okPressed(_:)))
        okButton.bezelStyle = .rounded
        okButton.keyEquivalent = "\r"
        okButton.translatesAutoresizingMaskIntoConstraints = false
        buttonBar.addSubview(okButton)

        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelPressed(_:)))
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}"
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        buttonBar.addSubview(cancelButton)

        let resetButton = NSButton(title: "Reset Defaults", target: self, action: #selector(resetPressed(_:)))
        resetButton.bezelStyle = .rounded
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        buttonBar.addSubview(resetButton)

        // --- Layout constraints ---
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: root.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -20),

            subtitle.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitle.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 20),
            subtitle.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -20),

            scrollView.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: sep.topAnchor, constant: -8),

            flipView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            flipView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            flipView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),

            mainStack.topAnchor.constraint(equalTo: flipView.topAnchor, constant: 4),
            mainStack.leadingAnchor.constraint(equalTo: flipView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: flipView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: flipView.bottomAnchor, constant: -4),
            mainStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),

            sep.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            sep.bottomAnchor.constraint(equalTo: buttonBar.topAnchor, constant: -8),

            buttonBar.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 20),
            buttonBar.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -20),
            buttonBar.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -12),
            buttonBar.heightAnchor.constraint(equalToConstant: 28),

            resetButton.leadingAnchor.constraint(equalTo: buttonBar.leadingAnchor),
            resetButton.centerYAnchor.constraint(equalTo: buttonBar.centerYAnchor),

            okButton.trailingAnchor.constraint(equalTo: buttonBar.trailingAnchor),
            okButton.centerYAnchor.constraint(equalTo: buttonBar.centerYAnchor),
            okButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 70),

            cancelButton.trailingAnchor.constraint(equalTo: okButton.leadingAnchor, constant: -8),
            cancelButton.centerYAnchor.constraint(equalTo: buttonBar.centerYAnchor),
        ])

        return window
    }

    // MARK: - Section Builders

    private func buildDisplaySection() {
        let content = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false

        let (fsSlider, fsLabel) = makeSliderRow(
            label: "Font Size", hint: "Size of ASCII characters",
            min: 8, max: 24, value: config.fontSize,
            target: self, action: #selector(fontSizeChanged(_:)),
            parent: content, topAnchor: content.topAnchor, topOffset: 4
        )
        fontSizeSlider = fsSlider
        fontSizeValueLabel = fsLabel
        updateFontSizeLabel()

        let (fSlider, fLabel) = makeSliderRow(
            label: "Step Size", hint: "Columns each creature jumps per tick — 1 = authentic terminal motion",
            min: 1, max: 8, value: Double(config.stepSize),
            target: self, action: #selector(stepSizeChanged(_:)),
            parent: content, topAnchor: fsSlider.bottomAnchor, topOffset: 14
        )
        fpsSlider = fSlider
        fpsSlider.numberOfTickMarks = 8
        fpsSlider.allowsTickMarkValuesOnly = true
        fpsValueLabel = fLabel
        updateStepSizeLabel()

        showBorderCheckbox = makeCheckbox("Show Border Frame", state: config.showBorder)
        showBorderCheckbox.translatesAutoresizingMaskIntoConstraints = false
        showBorderCheckbox.target = self
        showBorderCheckbox.action = #selector(toggleChanged(_:))
        content.addSubview(showBorderCheckbox)

        NSLayoutConstraint.activate([
            showBorderCheckbox.topAnchor.constraint(equalTo: fSlider.bottomAnchor, constant: 12),
            showBorderCheckbox.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 4),
            showBorderCheckbox.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -4),
        ])

        addSection(title: "Display", content: content, expanded: true)
    }

    private func buildAnimationSection() {
        let content = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false

        let (sSlider, sLabel) = makeSliderRow(
            label: "Overall Speed", hint: "Multiplier for all movement",
            min: 0.25, max: 3.0, value: config.speedMultiplier,
            target: self, action: #selector(speedChanged(_:)),
            parent: content, topAnchor: content.topAnchor, topOffset: 4
        )
        speedSlider = sSlider
        speedValueLabel = sLabel
        updateSpeedLabel()

        staggeredMovementCheckbox = makeCheckbox("Staggered Movement  —  fish tick at different offsets for a more organic look", state: config.staggeredMovement)
        staggeredMovementCheckbox.translatesAutoresizingMaskIntoConstraints = false
        staggeredMovementCheckbox.target = self
        staggeredMovementCheckbox.action = #selector(toggleChanged(_:))
        content.addSubview(staggeredMovementCheckbox)

        NSLayoutConstraint.activate([
            staggeredMovementCheckbox.topAnchor.constraint(equalTo: sSlider.bottomAnchor, constant: 12),
            staggeredMovementCheckbox.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 4),
            staggeredMovementCheckbox.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -4),
        ])

        addSection(title: "Animation", content: content, expanded: true)
    }

    private func buildFishSection() {
        let content = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false

        let (fdSlider, fdLabel) = makeSliderRow(
            label: "Fish Density", hint: "How many fish populate the tank",
            min: 3, max: 40, value: Double(config.fishDensity),
            target: self, action: #selector(fishDensityChanged(_:)),
            parent: content, topAnchor: content.topAnchor, topOffset: 4
        )
        fishDensitySlider = fdSlider
        fishDensityValueLabel = fdLabel
        updateFishDensityLabel()

        let (scSlider, scLabel) = makeSliderRow(
            label: "School Interval", hint: "Seconds between new school spawns",
            min: 10, max: 180, value: Double(config.schoolSpawnInterval),
            target: self, action: #selector(schoolIntervalChanged(_:)),
            parent: content, topAnchor: fdSlider.bottomAnchor, topOffset: 14
        )
        schoolIntervalSlider = scSlider
        schoolIntervalValueLabel = scLabel
        updateSchoolIntervalLabel()

        NSLayoutConstraint.activate([
            scSlider.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -4),
        ])

        addSection(title: "Fish & Schools", content: content, expanded: false)
    }

    private func buildBubblesSection() {
        let content = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false

        let (bSlider, bLabel) = makeSliderRow(
            label: "Ambient Bubbles", hint: "Rate of background bubble spawns",
            min: 5, max: 80, value: Double(config.bubbleSpawnInterval),
            target: self, action: #selector(bubbleChanged(_:)),
            parent: content, topAnchor: content.topAnchor, topOffset: 4
        )
        bubbleSlider = bSlider
        bubbleValueLabel = bLabel
        updateBubbleLabel()

        let (fbSlider, fbLabel) = makeSliderRow(
            label: "Fish Bubbles", hint: "Chance each fish emits a bubble per frame",
            min: 10, max: 500, value: Double(config.fishBubbleChance),
            target: self, action: #selector(fishBubbleChanged(_:)),
            parent: content, topAnchor: bSlider.bottomAnchor, topOffset: 14
        )
        fishBubbleSlider = fbSlider
        fishBubbleValueLabel = fbLabel
        updateFishBubbleLabel()

        NSLayoutConstraint.activate([
            fbSlider.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -4),
        ])

        addSection(title: "Bubbles", content: content, expanded: false)
    }

    private func buildCreaturesSection() {
        let content = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false

        let (crSlider, crLabel) = makeSliderRow(
            label: "Crabs", hint: "Number of crabs on the sand floor",
            min: 0, max: 6, value: Double(config.crabCount),
            target: self, action: #selector(crabChanged(_:)),
            parent: content, topAnchor: content.topAnchor, topOffset: 4
        )
        crabSlider = crSlider
        crabSlider.numberOfTickMarks = 7
        crabSlider.allowsTickMarkValuesOnly = true
        crabValueLabel = crLabel
        updateCrabLabel()

        let (jfSlider, jfLabel) = makeSliderRow(
            label: "Max Jellyfish", hint: "Maximum jellyfish present at once",
            min: 0, max: 5, value: Double(config.maxJellyfish),
            target: self, action: #selector(jellyfishChanged(_:)),
            parent: content, topAnchor: crSlider.bottomAnchor, topOffset: 14
        )
        jellyfishSlider = jfSlider
        jellyfishSlider.numberOfTickMarks = 6
        jellyfishSlider.allowsTickMarkValuesOnly = true
        jellyfishValueLabel = jfLabel
        updateJellyfishLabel()

        let (swSlider, swLabel) = makeSliderRow(
            label: "Seaweed Density", hint: "How much seaweed covers the floor",
            min: 5, max: 60, value: Double(config.seaweedDensity),
            target: self, action: #selector(seaweedChanged(_:)),
            parent: content, topAnchor: jfSlider.bottomAnchor, topOffset: 14
        )
        seaweedSlider = swSlider
        seaweedValueLabel = swLabel
        updateSeaweedLabel()

        // Toggles row
        jellyfishCheckbox = makeCheckbox("Jellyfish", state: config.jellyfishEnabled)
        jellyfishCheckbox.translatesAutoresizingMaskIntoConstraints = false
        jellyfishCheckbox.target = self
        jellyfishCheckbox.action = #selector(toggleChanged(_:))
        content.addSubview(jellyfishCheckbox)

        treasureCheckbox = makeCheckbox("Treasure Chest", state: config.treasureChestEnabled)
        treasureCheckbox.translatesAutoresizingMaskIntoConstraints = false
        treasureCheckbox.target = self
        treasureCheckbox.action = #selector(toggleChanged(_:))
        content.addSubview(treasureCheckbox)

        NSLayoutConstraint.activate([
            jellyfishCheckbox.topAnchor.constraint(equalTo: swSlider.bottomAnchor, constant: 12),
            jellyfishCheckbox.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 4),
            treasureCheckbox.topAnchor.constraint(equalTo: jellyfishCheckbox.topAnchor),
            treasureCheckbox.leadingAnchor.constraint(equalTo: jellyfishCheckbox.trailingAnchor, constant: 24),
            jellyfishCheckbox.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -4),
        ])

        addSection(title: "Creatures & Scenery", content: content, expanded: false)
    }

    private func buildRareEventsSection() {
        let content = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false

        let hintLabel = makeLabel("Control how often large creatures and ships appear. Lower values = more frequent.", size: 10)
        hintLabel.textColor = .secondaryLabelColor
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.lineBreakMode = .byWordWrapping
        hintLabel.maximumNumberOfLines = 2
        hintLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        content.addSubview(hintLabel)

        NSLayoutConstraint.activate([
            hintLabel.topAnchor.constraint(equalTo: content.topAnchor, constant: 4),
            hintLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 4),
            hintLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -4),
        ])

        // Shark
        let (skSlider, skLabel) = makeSliderRow(
            label: "Shark", hint: nil,
            min: 10, max: 180, value: Double(config.sharkSpawnInterval),
            target: self, action: #selector(sharkIntervalChanged(_:)),
            parent: content, topAnchor: hintLabel.bottomAnchor, topOffset: 10
        )
        sharkIntervalSlider = skSlider
        sharkIntervalValueLabel = skLabel
        updateSharkIntervalLabel()

        sharksCheckbox = makeCheckbox("", state: config.sharksEnabled)
        sharksCheckbox.translatesAutoresizingMaskIntoConstraints = false
        sharksCheckbox.target = self
        sharksCheckbox.action = #selector(toggleChanged(_:))
        content.addSubview(sharksCheckbox)
        NSLayoutConstraint.activate([
            sharksCheckbox.centerYAnchor.constraint(equalTo: skSlider.centerYAnchor),
            sharksCheckbox.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -4),
        ])

        // Whale
        let (wlSlider, wlLabel) = makeSliderRow(
            label: "Whale", hint: nil,
            min: 10, max: 180, value: Double(config.whaleSpawnInterval),
            target: self, action: #selector(whaleIntervalChanged(_:)),
            parent: content, topAnchor: skSlider.bottomAnchor, topOffset: 14
        )
        whaleIntervalSlider = wlSlider
        whaleIntervalValueLabel = wlLabel
        updateWhaleIntervalLabel()

        whalesCheckbox = makeCheckbox("", state: config.whalesEnabled)
        whalesCheckbox.translatesAutoresizingMaskIntoConstraints = false
        whalesCheckbox.target = self
        whalesCheckbox.action = #selector(toggleChanged(_:))
        content.addSubview(whalesCheckbox)
        NSLayoutConstraint.activate([
            whalesCheckbox.centerYAnchor.constraint(equalTo: wlSlider.centerYAnchor),
            whalesCheckbox.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -4),
        ])

        // Monster
        let (mnSlider, mnLabel) = makeSliderRow(
            label: "Sea Monster", hint: nil,
            min: 20, max: 300, value: Double(config.monsterSpawnInterval),
            target: self, action: #selector(monsterIntervalChanged(_:)),
            parent: content, topAnchor: wlSlider.bottomAnchor, topOffset: 14
        )
        monsterIntervalSlider = mnSlider
        monsterIntervalValueLabel = mnLabel
        updateMonsterIntervalLabel()

        monstersCheckbox = makeCheckbox("", state: config.monstersEnabled)
        monstersCheckbox.translatesAutoresizingMaskIntoConstraints = false
        monstersCheckbox.target = self
        monstersCheckbox.action = #selector(toggleChanged(_:))
        content.addSubview(monstersCheckbox)
        NSLayoutConstraint.activate([
            monstersCheckbox.centerYAnchor.constraint(equalTo: mnSlider.centerYAnchor),
            monstersCheckbox.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -4),
        ])

        // Ship
        let (shSlider, shLabel) = makeSliderRow(
            label: "Ship", hint: nil,
            min: 10, max: 120, value: Double(config.shipSpawnInterval),
            target: self, action: #selector(shipIntervalChanged(_:)),
            parent: content, topAnchor: mnSlider.bottomAnchor, topOffset: 14
        )
        shipIntervalSlider = shSlider
        shipIntervalValueLabel = shLabel
        updateShipIntervalLabel()

        shipsCheckbox = makeCheckbox("", state: config.shipsEnabled)
        shipsCheckbox.translatesAutoresizingMaskIntoConstraints = false
        shipsCheckbox.target = self
        shipsCheckbox.action = #selector(toggleChanged(_:))
        content.addSubview(shipsCheckbox)
        NSLayoutConstraint.activate([
            shipsCheckbox.centerYAnchor.constraint(equalTo: shSlider.centerYAnchor),
            shipsCheckbox.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -4),
            shSlider.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -4),
        ])

        addSection(title: "Rare Events", content: content, expanded: false)
    }

    // MARK: - Disclosure Section Infrastructure

    private func addSection(title: String, content: NSView, expanded: Bool) {
        // Each section is its own vertical NSStackView. NSStackView automatically
        // detaches hidden arranged subviews from layout, so hiding the content
        // wrapper causes the section to properly collapse.
        let sectionStack = NSStackView()
        sectionStack.orientation = .vertical
        sectionStack.alignment = .leading
        sectionStack.spacing = 0
        sectionStack.translatesAutoresizingMaskIntoConstraints = false

        // --- Header row: disclosure triangle + label ---
        let headerRow = NSView()
        headerRow.translatesAutoresizingMaskIntoConstraints = false

        let disclosure = NSButton()
        disclosure.translatesAutoresizingMaskIntoConstraints = false
        disclosure.bezelStyle = .disclosure
        disclosure.title = ""
        disclosure.state = expanded ? .on : .off
        disclosure.target = self
        disclosure.action = #selector(disclosureToggled(_:))
        headerRow.addSubview(disclosure)

        let headerLabel = makeLabel(title, bold: true, size: 13)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerRow.addSubview(headerLabel)

        let clickArea = NSButton()
        clickArea.translatesAutoresizingMaskIntoConstraints = false
        clickArea.isBordered = false
        clickArea.title = ""
        clickArea.isTransparent = true
        clickArea.target = self
        clickArea.action = #selector(headerClicked(_:))
        headerRow.addSubview(clickArea)

        NSLayoutConstraint.activate([
            disclosure.topAnchor.constraint(equalTo: headerRow.topAnchor, constant: 6),
            disclosure.leadingAnchor.constraint(equalTo: headerRow.leadingAnchor),
            disclosure.bottomAnchor.constraint(equalTo: headerRow.bottomAnchor, constant: -4),
            headerLabel.centerYAnchor.constraint(equalTo: disclosure.centerYAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: disclosure.trailingAnchor, constant: 4),
            clickArea.topAnchor.constraint(equalTo: headerRow.topAnchor),
            clickArea.bottomAnchor.constraint(equalTo: headerRow.bottomAnchor),
            clickArea.leadingAnchor.constraint(equalTo: headerLabel.leadingAnchor),
            clickArea.trailingAnchor.constraint(equalTo: headerRow.trailingAnchor),
        ])
        sectionStack.addArrangedSubview(headerRow)

        // --- Content wrapper (this is what gets hidden/shown) ---
        let contentWrapper = NSView()
        contentWrapper.translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        contentWrapper.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: contentWrapper.topAnchor, constant: 4),
            content.leadingAnchor.constraint(equalTo: contentWrapper.leadingAnchor, constant: 12),
            content.trailingAnchor.constraint(equalTo: contentWrapper.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: contentWrapper.bottomAnchor, constant: -4),
        ])
        contentWrapper.isHidden = !expanded
        sectionStack.addArrangedSubview(contentWrapper)

        // --- Separator ---
        let sep = NSBox()
        sep.boxType = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        sectionStack.addArrangedSubview(sep)

        // Store mapping from both buttons to the wrapper
        sectionContents[disclosure] = contentWrapper
        sectionContents[clickArea] = contentWrapper

        mainStack.addArrangedSubview(sectionStack)

        // Full width
        NSLayoutConstraint.activate([
            sectionStack.leadingAnchor.constraint(equalTo: mainStack.leadingAnchor),
            sectionStack.trailingAnchor.constraint(equalTo: mainStack.trailingAnchor),
            headerRow.leadingAnchor.constraint(equalTo: sectionStack.leadingAnchor),
            headerRow.trailingAnchor.constraint(equalTo: sectionStack.trailingAnchor),
            contentWrapper.leadingAnchor.constraint(equalTo: sectionStack.leadingAnchor),
            contentWrapper.trailingAnchor.constraint(equalTo: sectionStack.trailingAnchor),
            sep.leadingAnchor.constraint(equalTo: sectionStack.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: sectionStack.trailingAnchor),
        ])
    }

    @objc private func disclosureToggled(_ sender: NSButton) {
        guard let wrapper = sectionContents[sender] else { return }
        let expanding = sender.state == .on
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            ctx.allowsImplicitAnimation = true
            wrapper.isHidden = !expanding
            mainStack.window?.layoutIfNeeded()
        }
    }

    @objc private func headerClicked(_ sender: NSButton) {
        guard let wrapper = sectionContents[sender] else { return }
        for (button, view) in sectionContents where view === wrapper && button !== sender {
            button.state = button.state == .on ? .off : .on
            disclosureToggled(button)
            return
        }
    }

    // MARK: - Slider Row Builder

    /// Creates a labeled slider row inside `parent`, pinned to `topAnchor`.
    /// Returns the slider (use its bottomAnchor to chain the next row).
    @discardableResult
    private func makeSliderRow(
        label: String,
        hint: String?,
        min: Double,
        max: Double,
        value: Double,
        target: AnyObject,
        action: Selector,
        parent: NSView,
        topAnchor: NSLayoutYAxisAnchor,
        topOffset: CGFloat = 4
    ) -> (NSSlider, NSTextField) {
        let nameLabel = makeLabel(label, bold: false, size: 12)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(nameLabel)

        let valueLabel = makeLabel("", size: 11)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.alignment = .right
        valueLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        parent.addSubview(valueLabel)

        let slider = NSSlider(value: value, minValue: min, maxValue: max, target: target, action: action)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.isContinuous = true
        parent.addSubview(slider)

        var constraints = [
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: topOffset),
            nameLabel.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 4),

            valueLabel.topAnchor.constraint(equalTo: nameLabel.topAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -24),
            valueLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),

            slider.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            slider.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 4),
            slider.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -24),
        ]

        if let hint = hint {
            let hintLabel = makeLabel(hint, size: 10)
            hintLabel.textColor = .secondaryLabelColor
            hintLabel.translatesAutoresizingMaskIntoConstraints = false
            parent.addSubview(hintLabel)

            constraints.append(contentsOf: [
                hintLabel.topAnchor.constraint(equalTo: nameLabel.topAnchor, constant: 1),
                hintLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8),
            ])
        }

        NSLayoutConstraint.activate(constraints)

        return (slider, valueLabel)
    }

    // MARK: - Slider Actions

    @objc private func fontSizeChanged(_ sender: NSSlider) {
        config.fontSize = (sender.doubleValue * 2).rounded() / 2  // snap to 0.5
        updateFontSizeLabel()
    }

    @objc private func stepSizeChanged(_ sender: NSSlider) {
        config.stepSize = Int(sender.doubleValue.rounded())
        updateStepSizeLabel()
    }

    @objc private func speedChanged(_ sender: NSSlider) {
        config.speedMultiplier = (sender.doubleValue * 20).rounded() / 20  // snap to 0.05
        updateSpeedLabel()
    }

    @objc private func fishDensityChanged(_ sender: NSSlider) {
        config.fishDensity = Int(sender.doubleValue)
        updateFishDensityLabel()
    }

    @objc private func schoolIntervalChanged(_ sender: NSSlider) {
        config.schoolSpawnInterval = Int(sender.doubleValue)
        updateSchoolIntervalLabel()
    }

    @objc private func bubbleChanged(_ sender: NSSlider) {
        config.bubbleSpawnInterval = Int(sender.doubleValue)
        updateBubbleLabel()
    }

    @objc private func fishBubbleChanged(_ sender: NSSlider) {
        config.fishBubbleChance = Int(sender.doubleValue)
        updateFishBubbleLabel()
    }

    @objc private func crabChanged(_ sender: NSSlider) {
        config.crabCount = Int(sender.doubleValue.rounded())
        updateCrabLabel()
    }

    @objc private func jellyfishChanged(_ sender: NSSlider) {
        config.maxJellyfish = Int(sender.doubleValue.rounded())
        updateJellyfishLabel()
    }

    @objc private func seaweedChanged(_ sender: NSSlider) {
        config.seaweedDensity = Int(sender.doubleValue)
        updateSeaweedLabel()
    }

    @objc private func sharkIntervalChanged(_ sender: NSSlider) {
        config.sharkSpawnInterval = Int(sender.doubleValue)
        updateSharkIntervalLabel()
    }

    @objc private func whaleIntervalChanged(_ sender: NSSlider) {
        config.whaleSpawnInterval = Int(sender.doubleValue)
        updateWhaleIntervalLabel()
    }

    @objc private func monsterIntervalChanged(_ sender: NSSlider) {
        config.monsterSpawnInterval = Int(sender.doubleValue)
        updateMonsterIntervalLabel()
    }

    @objc private func shipIntervalChanged(_ sender: NSSlider) {
        config.shipSpawnInterval = Int(sender.doubleValue)
        updateShipIntervalLabel()
    }

    @objc private func toggleChanged(_ sender: NSButton) {
        config.sharksEnabled = sharksCheckbox.state == .on
        config.whalesEnabled = whalesCheckbox.state == .on
        config.monstersEnabled = monstersCheckbox.state == .on
        config.shipsEnabled = shipsCheckbox.state == .on
        config.jellyfishEnabled = jellyfishCheckbox.state == .on
        config.treasureChestEnabled = treasureCheckbox.state == .on
        config.showBorder = showBorderCheckbox.state == .on
        config.staggeredMovement = staggeredMovementCheckbox.state == .on
    }

    // MARK: - Label Updates

    private func updateFontSizeLabel() {
        fontSizeValueLabel.stringValue = String(format: "%.1f pt", config.fontSize)
    }

    private func updateStepSizeLabel() {
        let desc: String
        switch config.stepSize {
        case 1:    desc = "Terminal"
        case 2:    desc = "Classic"
        case 3, 4: desc = "Chunky"
        default:   desc = "Coarse"
        }
        fpsValueLabel.stringValue = "\(config.stepSize) col  \(desc)"
    }

    private func updateSpeedLabel() {
        let pct = Int(config.speedMultiplier * 100)
        speedValueLabel.stringValue = "\(pct)%"
    }

    private func updateFishDensityLabel() {
        let example = max(8, 120 / config.fishDensity)
        fishDensityValueLabel.stringValue = "~\(example) fish"
    }

    private func updateSchoolIntervalLabel() {
        schoolIntervalValueLabel.stringValue = "~\(config.schoolSpawnInterval)s"
    }

    private func updateBubbleLabel() {
        let interval = config.bubbleSpawnInterval
        let desc: String
        if interval < 15 { desc = "Very High" }
        else if interval < 25 { desc = "High" }
        else if interval < 40 { desc = "Medium" }
        else if interval < 60 { desc = "Low" }
        else { desc = "Very Low" }
        bubbleValueLabel.stringValue = "\(desc)"
    }

    private func updateFishBubbleLabel() {
        let chance = config.fishBubbleChance
        let pct = String(format: "%.1f%%", 100.0 / Double(chance))
        fishBubbleValueLabel.stringValue = "\(pct)/frame"
    }

    private func updateCrabLabel() {
        crabValueLabel.stringValue = "\(config.crabCount)"
    }

    private func updateJellyfishLabel() {
        jellyfishValueLabel.stringValue = "\(config.maxJellyfish)"
    }

    private func updateSeaweedLabel() {
        let example = max(4, 120 / config.seaweedDensity)
        seaweedValueLabel.stringValue = "~\(example) strands"
    }

    private func updateSharkIntervalLabel() {
        sharkIntervalValueLabel.stringValue = "~\(config.sharkSpawnInterval)s"
    }

    private func updateWhaleIntervalLabel() {
        whaleIntervalValueLabel.stringValue = "~\(config.whaleSpawnInterval)s"
    }

    private func updateMonsterIntervalLabel() {
        monsterIntervalValueLabel.stringValue = "~\(config.monsterSpawnInterval)s"
    }

    private func updateShipIntervalLabel() {
        shipIntervalValueLabel.stringValue = "~\(config.shipSpawnInterval)s"
    }

    // MARK: - Button Actions

    @objc private func okPressed(_ sender: NSButton) {
        config.save()
        if let parent = window.sheetParent {
            parent.endSheet(window, returnCode: .OK)
        } else {
            window.orderOut(sender)
        }
    }

    @objc private func cancelPressed(_ sender: NSButton) {
        if let parent = window.sheetParent {
            parent.endSheet(window, returnCode: .cancel)
        } else {
            window.orderOut(sender)
        }
    }

    @objc private func resetPressed(_ sender: NSButton) {
        AquariumConfig.resetToDefaults()
        config = AquariumConfig()
        reloadControls()
    }

    // MARK: - Reload All Controls

    private func reloadControls() {
        fontSizeSlider.doubleValue = config.fontSize
        fpsSlider.doubleValue = Double(config.stepSize)
        showBorderCheckbox.state = config.showBorder ? .on : .off
        speedSlider.doubleValue = config.speedMultiplier
        fishDensitySlider.doubleValue = Double(config.fishDensity)
        schoolIntervalSlider.doubleValue = Double(config.schoolSpawnInterval)
        bubbleSlider.doubleValue = Double(config.bubbleSpawnInterval)
        fishBubbleSlider.doubleValue = Double(config.fishBubbleChance)
        crabSlider.doubleValue = Double(config.crabCount)
        jellyfishSlider.doubleValue = Double(config.maxJellyfish)
        seaweedSlider.doubleValue = Double(config.seaweedDensity)
        sharkIntervalSlider.doubleValue = Double(config.sharkSpawnInterval)
        whaleIntervalSlider.doubleValue = Double(config.whaleSpawnInterval)
        monsterIntervalSlider.doubleValue = Double(config.monsterSpawnInterval)
        shipIntervalSlider.doubleValue = Double(config.shipSpawnInterval)
        sharksCheckbox.state = config.sharksEnabled ? .on : .off
        whalesCheckbox.state = config.whalesEnabled ? .on : .off
        monstersCheckbox.state = config.monstersEnabled ? .on : .off
        shipsCheckbox.state = config.shipsEnabled ? .on : .off
        jellyfishCheckbox.state = config.jellyfishEnabled ? .on : .off
        treasureCheckbox.state = config.treasureChestEnabled ? .on : .off
        staggeredMovementCheckbox.state = config.staggeredMovement ? .on : .off

        updateFontSizeLabel()
        updateStepSizeLabel()
        updateSpeedLabel()
        updateFishDensityLabel()
        updateSchoolIntervalLabel()
        updateBubbleLabel()
        updateFishBubbleLabel()
        updateCrabLabel()
        updateJellyfishLabel()
        updateSeaweedLabel()
        updateSharkIntervalLabel()
        updateWhaleIntervalLabel()
        updateMonsterIntervalLabel()
        updateShipIntervalLabel()
    }

    // MARK: - UI Helpers

    private func makeLabel(_ text: String, bold: Bool = false, size: CGFloat = 12) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = bold ? NSFont.boldSystemFont(ofSize: size) : NSFont.systemFont(ofSize: size)
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.isSelectable = false
        return label
    }

    private func makeCheckbox(_ title: String, state: Bool) -> NSButton {
        let checkbox = NSButton(checkboxWithTitle: title, target: nil, action: nil)
        checkbox.state = state ? .on : .off
        checkbox.font = NSFont.systemFont(ofSize: 12)
        return checkbox
    }
}

// MARK: - Flipped NSView for scroll content

private class FlippedView: NSView {
    override var isFlipped: Bool { true }
}
