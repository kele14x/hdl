# Copyright (c) 2021 kele14x

.PHONY: help lib all clean


help:
	@echo "hdl"
	@echo ""
	@echo "Type 'make <target>' to start, where <target> could be:"
	@echo ""
	@echo "    all   - make all projects & libraries"
	@echo "    lib   - make all libraries"
	@echo "    clean - clean build results"
	@echo "    help  - print this message"
	@echo ""


lib:
	$(MAKE) -C library/ all


all:
	$(MAKE) -C library/ all
	$(MAKE) -C projects/ all


clean:
	$(MAKE) -C library/ clean
	$(MAKE) -C projects/ clean
