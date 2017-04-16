#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <ctype.h>

#define DELTA  0xbadd1917
#define FDELTA 0x5ba322e0

void hexdump(void *ptr, int buflen) {
  unsigned char *buf = (unsigned char*)ptr;
  int i, j;
  for (i=0; i<buflen; i+=16) {
    printf("%06x: ", i);
    for (j=0; j<16; j++) 
      if (i+j < buflen)
        printf("%02x ", buf[i+j]);
      else
        printf("   ");
    printf(" ");
    for (j=0; j<16; j++) 
      if (i+j < buflen)
        printf("%c", isprint(buf[i+j]) ? buf[i+j] : '.');
    printf("\n");
  }
}

void encrypt (uint32_t* v, uint32_t* k) {
    uint32_t v0=v[0], v1=v[1], sum=0, i;           /* set up */
    uint32_t delta=DELTA; // 0x9e3779b9;                     /* a key schedule constant */
    uint32_t k0=k[0], k1=k[1], k2=k[2], k3=k[3];   /* cache key */
    for (i=0; i < 32; i++) {                       /* basic cycle start */
        sum += delta;
        v0 += ((v1<<4) + k0) ^ (v1 + sum) ^ ((v1>>5) + k1);
        v1 += ((v0<<4) + k2) ^ (v0 + sum) ^ ((v0>>5) + k3);
    }                                              /* end cycle */
    v[0]=v0; v[1]=v1;
}

int main(int argc, char *argv[]) {
	FILE *dfp, *kfp;
	uint8_t key[16];
	size_t dsize;

	kfp = fopen(argv[2], "rb");
	fread(key, 16, 1, kfp);
	fclose(kfp);

	dfp = fopen(argv[1], "rb");
	fseek(dfp, 0, SEEK_END);
	dsize = ftell(dfp);
	fseek(dfp, 0, SEEK_SET);

	uint8_t *buf = (uint8_t*)malloc(dsize);
	fread(buf, dsize, 1, dfp);
	fclose(dfp);

	hexdump(buf, dsize);

	int i;

	for(i=0; i<dsize; i+=8) {
		encrypt((uint32_t*)(buf+i), (uint32_t*)key);
	}

	hexdump(buf, dsize);

	dfp = fopen(argv[3], "wb");
	fwrite(buf, dsize, 1, dfp);
	fclose(dfp);

	printf("done\n");

	free(buf);

	return 0;
}
