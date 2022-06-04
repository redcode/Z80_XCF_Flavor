default: program

program:
	sjasmplus "sources/Z80 XCF Flavor.asm"

clean:
	-rm -f "Z80 XCF Flavor.tap"
