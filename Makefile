#
#   Copyright (C) MINZKN.COM
#   All rights reserved.
#
#   Maintainers
#     JaeHyuk Cho <mailto:minzkn@minzkn.com>
#

all: mbr-512.bin mbr.bin mbr-mz-512.bin mbr-mz.bin

clean:
	rm -f *.o mbr-512.bin mbr.bin mbr-mz-512.bin mbr-mz.bin

# 440 bytes (exclude partition table area)
mbr.bin: mbr-512.bin
	dd bs=440 count=1 if=$(<) of=$(@)
mbr-mz.bin: mbr-mz-512.bin
	dd bs=440 count=1 if=$(<) of=$(@)

# 512 bytes (include partition table area)
mbr-512.bin: mbr.o
	ld -Ttext 0x0 -s --oformat binary -e mzboot -o $(@) $(^)
mbr-mz-512.bin: mbr-mz.o
	ld -Ttext 0x0 -s --oformat binary -e mzboot -o $(@) $(^)

# compile
%.o: %.s
	as -o $(@) $(<)

# End of Makefile
