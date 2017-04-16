all:
	@echo "[CC] teacrypt.c"
	@gcc -o ./util/teacrypt ./util/teacrypt.c
	@echo "[TEA] flag.bin"
	@./util/teacrypt ./data/flag.bin ./data/key.bin ./data/flag.bin.enc
	@echo "[CC] vuln.c"
	@gcc -m32 -fno-stack-protector -o vuln vuln.c stub.s -static
	@echo "[ROP] find gadgets"
	@./gadgets.sh
	@echo "[VM] stage1.asm"
	@python ./util/vm_as.py stage1.asm stage1.bin 0x2000
	@echo "[CRYPT] stage1.bin"
	@python ./util/xor.py stage1.bin d1m1tr1z
	@echo "[VM] stage0.asm"
	@python ./util/vm_as.py stage0.asm stage0.bin
	@echo "[CC] input.s"
	@gcc -I./include/ -x assembler-with-cpp -Ttext=0 -o input.elf input.s -nostartfiles -nodefaultlibs
	@echo "[OBJCOPY] input.bin"
	@objcopy -j .text -O binary input.elf input.bin
