MODULES := $(patsubst %/Makefile,%,$(wildcard */Makefile))

.PHONY: lint test format clean

lint:
	@for module in $(MODULES); do \
		$(MAKE) -C $$module lint || exit $$?; \
	done

test:
	@for module in $(MODULES); do \
		$(MAKE) -C $$module test || exit $$?; \
	done

format:
	@for module in $(MODULES); do \
		$(MAKE) -C $$module format || exit $$?; \
	done

clean:
	rm -rf */sim_build
