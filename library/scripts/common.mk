VIVADO := vivado -mode batch -nolog -nojou -notrace -source

PART := xczu19eg-ffvc1760-2-i

CLEAN_TARGET += prj_dir/

.PHONY: help all project clean


help:
	@echo "Design: $(DESIGN)"
	@echo ""
	@echo "Type 'make <target>' to start, where <target> could be:"
	@echo ""
	@echo "    all      - make all jobs"
	@echo "    project  - create Vivado project"
	@echo "    clean    - clean output files"
	@echo "    help     - print this message"


all: project


project:
	$(VIVADO) ../scripts/common.tcl -tclargs --filesets $(DESIGN).flt


clean:
	-rm -rf $(CLEAN_TARGET)

