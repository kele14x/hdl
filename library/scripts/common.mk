VIVADO := vivado -mode batch -nolog -nojou -source

CLEAN_TARGET += prj/

.PHONY: all project clean

all: project

clean: 
	-rm -rf $(CLEAN_TARGET)

project:
	$(VIVADO) build.tcl
