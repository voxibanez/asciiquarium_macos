BUNDLE_NAME = AsciiFishtank
SAVER = $(BUNDLE_NAME).saver
SOURCES = $(wildcard Sources/AsciiFishtank/*.swift)
TEST_SOURCES = $(wildcard Tests/AsciiFishtankTests/*.swift)
ART_FILES = $(shell find Sources/AsciiFishtank/Resources/Art -name "*.txt" 2>/dev/null)
BINARY = $(SAVER)/Contents/MacOS/$(BUNDLE_NAME)
TEST_BINARY = .build/asciifishtank-tests
VERSION ?= dev
DIST_DIR = dist
PACKAGE_ROOT = $(DIST_DIR)/$(BUNDLE_NAME)-$(VERSION)
ARCHIVE = $(DIST_DIR)/$(BUNDLE_NAME)-$(VERSION).zip
ARCHIVE_NAME = $(BUNDLE_NAME)-$(VERSION).zip
SDK = $(shell xcrun --sdk macosx --show-sdk-path)
ARCH = $(shell uname -m)
MIN_VERSION = 14.0
PREFIX ?= /usr/local
CODESIGN_IDENTITY ?= -
CODESIGN_FLAGS ?=

all: $(SAVER)

$(SAVER): $(SOURCES) Sources/AsciiFishtank/Resources/Info.plist $(ART_FILES) LICENSE NOTICE
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
	mkdir -p $(SAVER)/Contents/Resources/Art
	rsync -a --delete --exclude '.DS_Store' --exclude '._*' \
		Sources/AsciiFishtank/Resources/Art/ $(SAVER)/Contents/Resources/Art/
	cp LICENSE NOTICE $(SAVER)/Contents/Resources/
	codesign --sign "$(CODESIGN_IDENTITY)" --force $(CODESIGN_FLAGS) $(SAVER)

install: $(SAVER)
	mkdir -p ~/Library/Screen\ Savers
	rm -rf ~/Library/Screen\ Savers/$(SAVER)
	cp -R $(SAVER) ~/Library/Screen\ Savers/

install-prefix: $(SAVER)
	rm -rf $(PREFIX)/$(SAVER)
	mkdir -p $(PREFIX)
	cp -R $(SAVER) $(PREFIX)/

test: $(SOURCES) $(TEST_SOURCES)
	mkdir -p .build
	swiftc $(SOURCES) $(TEST_SOURCES) \
		-o $(TEST_BINARY) \
		-module-name $(BUNDLE_NAME)Tests \
		-sdk $(SDK) \
		-target $(ARCH)-apple-macosx$(MIN_VERSION) \
		-framework ScreenSaver \
		-framework AppKit \
		-framework QuartzCore
	$(TEST_BINARY)

package: $(SAVER)
	rm -rf $(DIST_DIR)
	mkdir -p $(PACKAGE_ROOT)
	cp -R $(SAVER) $(PACKAGE_ROOT)/
	cp LICENSE NOTICE README.md $(PACKAGE_ROOT)/
	find $(PACKAGE_ROOT) \( -name '.DS_Store' -o -name '._*' \) -delete
	rm -f $(ARCHIVE)
	cd $(DIST_DIR) && zip -qry -X $(ARCHIVE_NAME) $(BUNDLE_NAME)-$(VERSION)

uninstall:
	rm -rf ~/Library/Screen\ Savers/$(SAVER)

clean:
	rm -rf $(SAVER) $(DIST_DIR)

.PHONY: all install install-prefix test package uninstall clean
