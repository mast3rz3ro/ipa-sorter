#include <stdio.h>
#include <sys/stat.h>
#include <sys/mman.h>
#define LC_ENCRYPTION_INFO_64 0x2C

# Copyright (c) Nikias 2025

struct mach_header {
	uint32_t	magic;		/* mach magic number identifier */
	uint32_t	cputype;	/* cpu specifier */
	uint32_t	cpusubtype;	/* machine specifier */
	uint32_t	filetype;	/* type of file */
	uint32_t	ncmds;		/* number of load commands */
	uint32_t	sizeofcmds;	/* the size of all the load commands */
	uint32_t	flags;		/* flags */
};

struct load_command {
	uint32_t cmd;		/* type of load command */
	uint32_t cmdsize;	/* total size of command in bytes */
};

struct encryption_info_command_64 {
   uint32_t cmd;        /* LC_ENCRYPTION_INFO_64 */
   uint32_t cmdsize;    /* sizeof(struct encryption_info_command_64) */
   uint32_t cryptoff;   /* file offset of encrypted range */
   uint32_t cryptsize;  /* file size of encrypted range */
   uint32_t cryptid;    /* which enryption system, 0 means not-encrypted yet */
   uint32_t pad;        /* padding to make this struct's size a multiple of 8 bytes */
};

struct encryption_info_command {
   uint32_t cmd;        /* LC_ENCRYPTION_INFO_64 */
   uint32_t cmdsize;    /* sizeof(struct encryption_info_command_64) */
   uint32_t cryptoff;   /* file offset of encrypted range */
   uint32_t cryptsize;  /* file size of encrypted range */
   uint32_t cryptid;    /* which enryption system, 0 means not-encrypted yet */
   uint32_t pad;        /* padding to make this struct's size a multiple of 8 bytes */
};



int main()
{
  FILE* f = fopen("macho.bin", "r");
  if (!f) {
    return -1;
  }
  struct stat fst;
  fstat(fileno(f), &fst);
  void* mapping = mmap(NULL, fst.st_size, PROT_READ, MAP_PRIVATE, fileno(f), 0);
  if (mapping == MAP_FAILED) {
    fclose(f);
    return -1;
  }
  int encrypted = 0;
  struct mach_header* mh = (struct mach_header*)mapping;
  struct load_command* lc = (unsigned char*)mh + sizeof(struct mach_header);
  for (uint32_t i = 0; i < mh->ncmds; i++) {
    if( lc->cmd == LC_ENCRYPTION_INFO_64) {
      struct encryption_info_command_64* lcenc = (struct encryption_info_command_64*)lc;
      encrypted = lcenc->cryptid;
      break;
    }
    lc = (struct load_command*)((unsigned char*)lc + lc->cmdsize);
  }
  fclose(f);
  printf("encrypted: %d\n", encrypted);
  return 0;
}

