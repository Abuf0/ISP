genreg:
	@echo "Generating RTL..."
	peakrdl regblock rdl/regmap.rdl -o rtl/ --cpuif passthrough --default-reset arst_n --hwif-report

gendoc:
	@echo "Generating Documents of html/md/pdf"
	mkdir -p doc/html
	peakrdl html rdl/regmap.rdl -o doc/html --title "Registers"
	mkdir -p doc/markdown
	peakrdl markdown rdl/regmap.rdl -o doc/markdown/Registers.md
	mkdir -p doc/pdf
	peakrdl pdf rdl/regmap.rdl -o doc/pdf/Registers.pdf
	