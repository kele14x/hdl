# Shared cocotb entry point. Missing tests and an empty simulator selection are
# configuration failures; pytest also fails when tests/ contains no test cases.
.PHONY: test
test:
	@test -d tests || { echo "ERROR: $(MODULE) has no tests/ directory" >&2; exit 1; }
	@test -n "$(strip $(SIMULATORS))" || { echo "ERROR: SIMULATORS must not be empty" >&2; exit 1; }
	@for sim in $(SIMULATORS); do \
		echo "--- cocotb ($(MODULE)): $$sim ---"; \
		SIM=$$sim $(PYTEST) -q tests || exit $$?; \
	done
