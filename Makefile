# The project currently needs the macOS 27 beta SDK; default to Xcode-beta when
# it's installed. On a machine/runner without Xcode-beta (e.g. a GitHub-hosted
# macos-latest runner), fall back to whatever toolchain `xcode-select` already
# points at instead of a nonexistent path. An explicitly supplied DEVELOPER_DIR
# (env or command line) always wins over both.
# Override on the command line: `make abi-check DEVELOPER_DIR=…` or point at a
# different beta install with `make abi-check XCODE_BETA=…`.
XCODE_BETA := /Applications/Xcode-beta.app/Contents/Developer
HAVE_BETA := $(if $(wildcard $(XCODE_BETA)),1,)
DEVELOPER_DIR ?= $(if $(HAVE_BETA),$(XCODE_BETA),$(shell xcode-select -p))
export DEVELOPER_DIR
SDK := $(shell xcrun --show-sdk-path)
TARGET := arm64-apple-macosx14.0
DIGESTER := xcrun swift-api-digester
MODULES := .build/release
ABI := abi/AinkradAppKitContract.abi.json
# AinkradSignal is checked too, as of generation 9.
#
# It was not, and the gap was real: `HostServices.signals` puts
# `PluginSignalEmitter` in the contract, whose signature is made of
# `SignalEvent`/`SignalSeverity`/`SignalAction` — so `AinkradSignal` became part
# of the plugin surface without becoming part of the check. Removing a public
# stored property from `RoutingRules` passed cleanly, not because it was safe
# but because the digester was never pointed at the module. That is the
# generation-8 failure shape exactly: a check that passes because it cannot see
# the thing that broke.
ABI_SIGNAL := abi/AinkradSignal.abi.json
ALLOWLIST := abi/breakage-allowlist.txt

.PHONY: build abi-baseline abi-check test
build:
	swift build -c release

# The baseline tracks AinkradAppKitContract ONLY.
#
# It used to cover the whole package, so every HUD component tweak registered as
# an ABI event and the committed baseline was ~90% component churn — real
# contract changes had nothing to stand out against. The contract is the only
# module whose ABI can stop an installed plugin from loading, so it is the only
# one held to this standard. AinkradAppKitUI is free to move.

# Regenerate the committed ABI baseline (run after an intentional, reviewed change).
abi-baseline: build
	$(DIGESTER) -dump-sdk -abi -module AinkradAppKitContract \
	  -o $(ABI) -I $(MODULES) -sdk $(SDK) -target $(TARGET)
	$(DIGESTER) -dump-sdk -abi -module AinkradSignal \
	  -o $(ABI_SIGNAL) -I $(MODULES) -sdk $(SDK) -target $(TARGET)

# Fail if the current module has an ABI break vs. the committed baseline.
# The pass/fail decision lives in scripts/abi-check.sh — see the comment there
# for why `grep "has been"` was not enough: it cannot see added protocol
# requirements, which are exactly the break library evolution does NOT cover.
#
# ## Why this is toolchain-gated
#
# swift-api-digester loads the *binary* .swiftmodule that `swift build` just
# produced. A binary swiftmodule is only readable by the exact compiler build
# that wrote it. When the digester's toolchain differs from the one that built
# the module, the load fails and -diagnose-sdk does NOT abort — it diffs an
# EMPTY module against the baseline and reports every single type in the
# contract as "has been removed". That is a false ABI break, and it is what a
# GitHub-hosted macos runner produced (log: `Failed to load module:
# AinkradAppKitContract`, then 39 bogus removals).
#
# Note this is a *toolchain* constraint, not an SDK one: running the beta
# digester against the CommandLineTools SDK passes fine, while running the CLT
# digester against a beta-built module fails. So the guard is on Xcode-beta —
# the toolchain that builds this package and generated the committed baseline.
#
# There is no way to make the check meaningful under a foreign toolchain, and
# making it merely *pass* would mean deleting the guardrail. So: run it when
# the beta toolchain is here, and when it is not, skip LOUDLY. A release is
# still covered — scripts/preflight.sh in the host repo (invoked by
# scripts/release.sh) runs this check on a machine that does have Xcode-beta.
#
# Force it anyway (e.g. after moving the baseline to another toolchain):
#   make abi-check ABI_CHECK_FORCE=1
ABI_CHECK_FORCE ?=

abi-check:
ifeq ($(strip $(HAVE_BETA))$(strip $(ABI_CHECK_FORCE)),)
	@printf '%s\n' \
	  "$(if $(CI),::warning title=ABI check SKIPPED::,)" \
	  "==============================================================" \
	  "  ABI CHECK SKIPPED — IT DID NOT RUN. THIS IS NOT A PASS." \
	  "==============================================================" \
	  "  Reason: Xcode-beta is not installed at" \
	  "          $(XCODE_BETA)" \
	  "  swift-api-digester can only read a .swiftmodule written by its" \
	  "  own compiler build. Under any other toolchain it fails to load" \
	  "  the module and reports the ENTIRE contract as removed, which is" \
	  "  a false result, not a check." \
	  "" \
	  "  The contract is therefore UNVERIFIED in this environment." \
	  "  It is verified before every release by scripts/preflight.sh in" \
	  "  the host repo, on a machine with the beta toolchain." \
	  "=============================================================="
else
	$(MAKE) build
	$(DIGESTER) -diagnose-sdk -abi -module AinkradAppKitContract \
	  -baseline-path $(ABI) -I $(MODULES) -sdk $(SDK) -target $(TARGET) \
	  -breakage-allowlist-path $(ALLOWLIST) -o abi/report.txt
	@./scripts/abi-check.sh abi/report.txt
	$(DIGESTER) -diagnose-sdk -abi -module AinkradSignal \
	  -baseline-path $(ABI_SIGNAL) -I $(MODULES) -sdk $(SDK) -target $(TARGET) \
	  -breakage-allowlist-path $(ALLOWLIST) -o abi/report-signal.txt
	@./scripts/abi-check.sh abi/report-signal.txt
endif

test:
	swift test
