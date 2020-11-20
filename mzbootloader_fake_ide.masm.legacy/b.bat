@rem Build script for DOS
@TASM /t mbr.asm
@TLINK /x /k mbr.obj
@DEL mbr.obj
@EXE2MZ mbr.exe mbr.bin
@DEL mbr.exe
@TASM /t loader.asm
@TLINK /x /k loader.obj
@DEL loader.obj
@TASM /t fl.asm
@TLINK /x /k fl.obj
@EXE2MZ loader.exe loader.bin
@DEL loader.exe
@COPY mbr.bin + loader.bin sum.bin
@rem End of script for DOS
