BUNDLE_NAME = AsciiFishtank
SAVER = $(BUNDLE_NAME).saver
SOURCES = $(wildcard Sources/AsciiFishtank/*.swift)
ART_FILES = $(shell find Sources/AsciiFishtank/Resources/Art -name "*.txt" 2>/dev/null)
BINARY = $(SAVER)/Contents/MacOS/$(BUNDLE_NAME)
SDK = $(shell xcrun --sdk macosx --show-sdk-path)
ARCH = $(shell uname -m)
MIN_VERSION = 14.0

all: $(SAVER)

$(SAVER): $(SOURCES) Sources/AsciiFishtank/Resources/Info.plist $(ART_FILES)
	mkdir -p $(SAVER)/Contents/MacOS
	mkdir -p $(SAVER)/Contents/Resources
	swiftc $(SOURCES) \
		-o $(BINARY) \
		-emit-library \
		-module-name $(BUNDLE_NAME) \
		-sdk $(SDK) \
		-target $(ARCH)-apple-macosx$(MIN_VERSION) \
		-framework ScreenSaver \
		-framework AppKit \
		-framework QuartzCore \
		-Xlinker -bundle \
		-O \
		-whole-module-optimization
	cp Sources/AsciiFishtank/Resources/Info.plist $(SAVER)/Contents/Info.plist
	cp -R Sources/AsciiFishtank/Resources/Art $(SAVER)/Contents/Resources/
	codesign -s - -f $(SAVER)

install: $(SAVER)
	mkdir -p ~/Library/Screen\ Savers
	rm -rf ~/Library/Screen\ Savers/$(SAVER)
	cp -R $(SAVER) ~/Library/Screen\ Savers/

uninstall:
	rm -rf ~/Library/Screen\ Savers/$(SAVER)

clean:
	rm -rf $(SAVER)

.PHONY: all install uninstall clean
