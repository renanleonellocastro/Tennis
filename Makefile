# Developer entry points. Requires the Connect IQ SDK; see CONTRIBUTING.md
# for the one time setup (SDK, device files and a signing key).

DEVICE ?= fr55
KEY ?= $(HOME)/.garmin-keys/developer_key.der
TYPE_CHECK ?= 2
# Extra compiler options of `make build`. `BUILD_OPTIONS=-r` makes the
# release build that the store package holds: it takes less memory on the
# watch, and an error report carries no line numbers.
BUILD_OPTIONS ?=
# One device per screen shape: small round MIP, round AMOLED, rectangular.
SHAPE_DEVICES ?= fr55 venu2 venusq2

SDK_BIN := $(shell connect-iq-sdk-manager sdk current-path --bin 2>/dev/null)
ifeq ($(SDK_BIN),)
SDK_BIN := $(shell ls -d "$(HOME)/Library/Application Support/Garmin/ConnectIQ/Sdks"/*/bin 2>/dev/null | sort | tail -1)
endif

MONKEYC = "$(SDK_BIN)/monkeyc"
MONKEYDO = "$(SDK_BIN)/monkeydo"
SIMULATOR = "$(SDK_BIN)/connectiq"

UV ?= uv
RUN = $(UV) run --frozen
TOOLS_COVERAGE = --cov=tools --cov-branch --cov-report=term-missing --cov-fail-under=100

.PHONY: help key build build-shapes build-all test-build test sim package strings icon key-labels clean \
	resources-check audit lint-tools test-tools function-length function-length-gate check

help:
	@echo "Targets:"
	@echo "  key            Generate a developer signing key (once)"
	@echo "  build          Compile a debug build for DEVICE (default: fr55); BUILD_OPTIONS=-r for a release build"
	@echo "  build-shapes   Compile for one device per screen shape"
	@echo "  build-all      Compile for every device in manifest.xml, one result per device"
	@echo "  test-build     Compile the unit test build for DEVICE"
	@echo "  sim            Launch the Connect IQ simulator"
	@echo "  test           Run unit tests on the simulator (start 'make sim' first)"
	@echo "  package        Build the store ready .iq package (all devices)"
	@echo "  strings        Regenerate the string tables from the strings.xml files"
	@echo "  icon           Regenerate the launcher icon"
	@echo "  key-labels     Regenerate the images of the key labels"
	@echo "  check          Run every local quality gate (see docs/QUALITY.md)"
	@echo "  function-length  List functions over 12 lines, longest first"
	@echo "  clean          Remove build output"

key:
	@mkdir -p $(dir $(KEY))
	@test -f $(KEY) || ( \
		openssl genrsa -out $(KEY:.der=.pem) 4096 && \
		openssl pkcs8 -topk8 -inform PEM -outform DER \
			-in $(KEY:.der=.pem) -out $(KEY) -nocrypt && \
		echo "Developer key created at $(KEY)" )

build: key
	@mkdir -p bin
	$(MONKEYC) -f monkey.jungle -d $(DEVICE) -o bin/Tennis-$(DEVICE).prg \
		-y $(KEY) -w -l $(TYPE_CHECK) $(BUILD_OPTIONS)

build-shapes:
	@for device in $(SHAPE_DEVICES); do \
		$(MAKE) --no-print-directory build DEVICE=$$device || exit 1; \
	done

# Every manifest device on its own, so one run names each device that fails.
# About a minute and a half on a laptop and longer on a CI runner, so it is a
# release step and not part of `make check`.
build-all: key
	python3 scripts/build_all_devices.py --monkeyc $(MONKEYC) --key $(KEY) \
		--type-check $(TYPE_CHECK) $(BUILD_ALL_OPTIONS)

test-build: key
	@mkdir -p bin
	$(MONKEYC) -f monkey.jungle -d $(DEVICE) -o bin/Tennis-tests.prg \
		-y $(KEY) -w -l $(TYPE_CHECK) --unit-test

sim:
	$(SIMULATOR) &

# monkeydo's exit code is unreliable; gate on the printed result summary.
test: test-build
	@$(MONKEYDO) bin/Tennis-tests.prg $(DEVICE) -t | tee bin/test-output.log; \
	grep -q "^PASSED" bin/test-output.log && ! grep -qE "^FAILED|^ERRORED" bin/test-output.log

package: key
	@mkdir -p dist
	$(MONKEYC) -e -f monkey.jungle -o dist/Tennis.iq -y $(KEY) -r -w

strings:
	python3 scripts/generate_strings.py

# Pillow is fetched by uv for this run only.
icon:
	$(UV) run --frozen --with pillow python scripts/generate_icon.py

clean:
	rm -rf bin dist

# The images of the key labels, for the watches that cannot draw text along
# the round edge. Run it after changing the text or the place of a label.
key-labels:
	$(RUN) python tools/key_labels.py

# XML validity, string catalogs in sync, the generated table and the images
# of the key labels up to date.
resources-check:
	python3 scripts/check_resources.py
	$(RUN) python tools/key_labels.py --check

audit:
	python3 scripts/audit_api_usage.py

lint-tools:
	$(RUN) ruff check tools
	$(RUN) ruff format --check tools
	MYPYPATH=tools $(RUN) mypy --strict tools

test-tools:
	$(RUN) pytest tools/tests -q -p no:cacheprovider -o pythonpath=tools $(TOOLS_COVERAGE)

# Functions whose body passes 12 lines (rule 1 of docs/QUALITY.md), longest first.
function-length:
	$(RUN) python tools/check_function_length.py

# Strict: fails when any function body passes 12 lines.
function-length-gate:
	$(RUN) python tools/check_function_length.py --strict

# The simulator suite needs a running simulator, so it stays a separate step: make sim, then make test.
check: resources-check audit build-shapes lint-tools test-tools function-length-gate
