DOC_DIR := doc
LOWPHY_MD := $(DOC_DIR)/Design Specification for LowPHY.md
LOWPHY_PDF := $(DOC_DIR)/Design Specification for LowPHY.pdf
LOWPHY_TITLE := Design Specification for LowPHY
DRAWIO := draw.io.exe
DRAWIO_FILES := $(wildcard $(DOC_DIR)/*.drawio)
DRAWIO_SVGS := $(DRAWIO_FILES:.drawio=.svg)

.PHONY: all docs lowphy-doc diagrams clean

all: docs

docs: lowphy-doc

diagrams: $(DRAWIO_SVGS)

$(DOC_DIR)/%.svg: $(DOC_DIR)/%.drawio
	"$(DRAWIO)" --export --format svg --output "$@" "$<"

lowphy-doc: diagrams
	pandoc "$(LOWPHY_MD)" -o "$(LOWPHY_PDF)" --metadata title="$(LOWPHY_TITLE)" --table-of-contents --toc-depth=3 --resource-path="$(DOC_DIR)" --pdf-engine=weasyprint

clean:
	pwsh -NoProfile -Command "if (Test-Path -LiteralPath '$(LOWPHY_PDF)') { Remove-Item -LiteralPath '$(LOWPHY_PDF)' }; Get-ChildItem -LiteralPath '$(DOC_DIR)' -Filter '*.svg' | Where-Object { Test-Path -LiteralPath ($_.FullName -replace '\\.svg$$', '.drawio') } | ForEach-Object { Remove-Item -LiteralPath $_.FullName }"
