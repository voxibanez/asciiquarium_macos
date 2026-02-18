BUNDLE_NAME = AsciiFishtank
SAVER = $(BUNDLE_NAME).saver
SOURCES = $(wildcard Sources/*.swift)
ART_FILES = $(shell find Resources/Art -name "*.txt" 2>/dev/null)
BINARY = $(SAVER)/Contents/MacOS/$(BUNDLE_NAME)
SDK = $(shell xcrun --sdk macosx --show-sdk-path)
ARCH = $(shell uname -m)
MIN_VERSION = 14.0

all: $(SAVER)

$(SAVER): $(SOURCES) Resources/Info.plist $(ART_FILES)
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
		-Xlinker -bundle \
		-O \
		-whole-module-optimization
	cp Resources/Info.plist $(SAVER)/Contents/Info.plist
	cp -R Resources/Art $(SAVER)/Contents/Resources/
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
