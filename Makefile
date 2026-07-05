.PHONY: pdf pdf-all clean

pdf:
	./scripts/build-pdf.sh

pdf-all:
	./scripts/build-pdf.sh metadata/product.yaml --all

clean:
	rm -rf dist
