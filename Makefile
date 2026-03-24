APP      := ClaudeWatch
BUNDLE   := Claude Watch.app
RELEASE  := .build/release/$(APP)
INSTALL  := /Applications/$(BUNDLE)
DMG      := ClaudeWatch.dmg
DMG_DIR  := .dmg_staging

REPO     := SerhiiBoo/ClaudeWatch
VERSION  := $(shell /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)
TAG      := v$(VERSION)

# GitHub token: set GITHUB_TOKEN env var or store in ~/.config/claudewatch/token
GITHUB_TOKEN ?= $(shell cat ~/.config/claudewatch/token 2>/dev/null)

# ── Build ──────────────────────────────────────────────────────────────────────

.PHONY: build bundle run install dmg clean release

build:
	swift build -c release 2>&1

# Create a proper .app bundle that macOS recognises
bundle: build
	@echo "→ Creating $(BUNDLE)..."
	@rm -rf "$(BUNDLE)"
	@mkdir -p "$(BUNDLE)/Contents/MacOS"
	@mkdir -p "$(BUNDLE)/Contents/Resources"
	@cp "$(RELEASE)"            "$(BUNDLE)/Contents/MacOS/$(APP)"
	@cp Resources/Info.plist  "$(BUNDLE)/Contents/"
	@cp Resources/AppIcon.icns "$(BUNDLE)/Contents/Resources/"
	@# Ad-hoc code signature (required to run on macOS 13+)
	@codesign --force --deep --sign - "$(BUNDLE)"
	@echo "✓ $(BUNDLE) ready"

run: bundle
	@echo "→ Launching $(APP)..."
	@open "$(BUNDLE)"

install: bundle
	@echo "→ Installing to /Applications..."
	@rm -rf "$(INSTALL)"
	@cp -r "$(BUNDLE)" /Applications/
	@# Force LaunchServices to re-index so the icon shows in notifications/Spotlight
	@/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$(INSTALL)"
	@echo "✓ Installed. Launch with: open \"$(INSTALL)\""

dmg: bundle
	@echo "→ Creating $(DMG)..."
	@rm -rf "$(DMG_DIR)" "$(DMG)"
	@mkdir -p "$(DMG_DIR)"
	@cp -r "$(BUNDLE)" "$(DMG_DIR)/"
	@ln -s /Applications "$(DMG_DIR)/Applications"
	@hdiutil create -volname "Claude Watch" \
	    -srcfolder "$(DMG_DIR)" \
	    -ov -format UDZO \
	    "$(DMG)"
	@rm -rf "$(DMG_DIR)"
	@echo "✓ $(DMG) ready"

clean:
	@rm -rf .build "$(BUNDLE)" "$(DMG_DIR)" "$(DMG)"
	@echo "✓ Cleaned"

# ── Release ─────────────────────────────────────────────────────────────────────
# Usage: make release
# Requires GITHUB_TOKEN env var or ~/.config/claudewatch/token

release: dmg
	@[ -n "$(GITHUB_TOKEN)" ] || { echo "✗ GITHUB_TOKEN not set. Export it or save to ~/.config/claudewatch/token"; exit 1; }
	@echo "→ Tagging $(TAG)..."
	@git tag -a "$(TAG)" -m "Release $(TAG)" 2>/dev/null || echo "  (tag already exists, skipping)"
	@git push origin "$(TAG)" 2>/dev/null || echo "  (tag already pushed, skipping)"
	@echo "→ Creating GitHub release $(TAG)..."
	@RELEASE_ID=$$(curl -sf -X POST \
	    -H "Authorization: token $(GITHUB_TOKEN)" \
	    -H "Accept: application/vnd.github+json" \
	    https://api.github.com/repos/$(REPO)/releases \
	    -d "{\"tag_name\":\"$(TAG)\",\"name\":\"Claude Watch $(TAG)\",\"body\":\"See [CHANGELOG.md](https://github.com/$(REPO)/blob/main/CHANGELOG.md) for details.\",\"draft\":false,\"prerelease\":false}" \
	    | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])") && \
	echo "→ Uploading $(DMG)..." && \
	curl -sf -X POST \
	    -H "Authorization: token $(GITHUB_TOKEN)" \
	    -H "Content-Type: application/octet-stream" \
	    "https://uploads.github.com/repos/$(REPO)/releases/$${RELEASE_ID}/assets?name=$(DMG)" \
	    --data-binary @"$(DMG)" > /dev/null && \
	echo "✓ Released: https://github.com/$(REPO)/releases/tag/$(TAG)"

# Local overrides (gitignored) — e.g. preview-on / preview-off targets
-include Makefile.local
