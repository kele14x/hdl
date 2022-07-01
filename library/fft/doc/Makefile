
.PHONY: all clean

all: fft.pdf

clean:
	-rm fft.pdf

fft.pdf: fft.md
	pandoc --number-sections -o fft.pdf --pdf-engine=xelatex --metadata-file=meta.yaml fft.md
