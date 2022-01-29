# Copyright (c) 2021 kele14x

.PHONY: help lib all clean


help:
	@echo ""
	@echo "Type 'make <target>' to start, where <target> could be:"
	@echo ""
	@echo "    all   - make all projects"
	@echo "    lib   - make all libraries"
	@echo "    clean - clean build results"


lib:
	$(MAKE) -C library/ all


all: 
	$(MAKE) -C library/ all


clean:
	$(MAKE) -C projects/ clean
