PRODUCTS := build/DerivedData/Build/Products
CONFIG ?= Debug
APP := $(PRODUCTS)/$(CONFIG)/Breather.app

.PHONY: build run install test clean

## Build into build/. `make build CONFIG=Release` for a release build.
build:
	xcodegen generate --quiet
	xcodebuild -project Breather.xcodeproj -scheme Breather -configuration $(CONFIG) \
		-destination 'generic/platform=macOS' -derivedDataPath build/DerivedData -quiet build

## Build and start the debug app.
run: build
	pkill -x Breather || true
	open $(APP)

## Build a release copy, put it in ~/Applications and start it.
install:
	$(MAKE) build CONFIG=Release
	pkill -x Breather || true
	mkdir -p ~/Applications
	rm -rf ~/Applications/Breather.app
	cp -R $(PRODUCTS)/Release/Breather.app ~/Applications/
	open ~/Applications/Breather.app

test:
	swift test --package-path Packages/BreatherCore

clean:
	rm -rf build Breather.xcodeproj
