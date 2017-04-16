#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#include <stdio.h>
#include <stdint.h>

FILE *fh;
struct stat	st;

void chk(char *c, char v0, char v1) {
	
}

void vuln(FILE *f, size_t fsize) {
	char buf[0x100];
	int i;
	uint32_t checksum = 0xc3e089aa;

	fread(buf, fsize, 1, f);

	for(i = 0; i < 0x100; i++) {
		chk(&buf[i], 12, 13);
		checksum += buf[i];
	}

	checksum += 0xc3c189;
	checksum += 0xc3c289;
	checksum += 0xc3c389;
	checksum |= 0xffc30174;

	printf("file checksum: %x\n", checksum);
}

int main(int argc, char *argv[]) {
	char dummybuf[8192];

	if (stat(argv[1], &st) != 0) {
		printf("Could not open input file '%s'\n", argv[1]);
		return -1;
	}

	fh = fopen(argv[1], "rb");

	vuln(fh, st.st_size);

	printf("DONE!\n");

	return 0;
}
