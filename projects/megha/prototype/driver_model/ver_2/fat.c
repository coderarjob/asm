
#include "device.h"
#include "fs.h"
#include <string.h>	// strcpy
#include <stdlib.h> // malloc
#include <stdio.h>
#include "panic.h"
#include "vfs.h"

int fat_read(struct file *f, char *buffer, int size);
struct file* fat_open(struct mount_point *mp, char *filename);
int fat_read_bpb(struct file *f, struct mount_point *mp);

struct file_operations fat_fo = {
	.open = fat_open,
	.read = fat_read,
};

struct filesystem_operations fat_fso = {
	.read_bpb = fat_read_bpb,
	.format = NULL
};

struct filesystem fat_fsi = {
	.fsname = "FAT",
	.fso = &fat_fso,
	.fo = &fat_fo
};

static struct file files[10];
static int file_count;

void fat_init()
{
	printf("Registering fat file system.\n");
	register_fs(&fat_fsi);
}

int fat_read_bpb(struct file *f, struct mount_point *mp)
{
	printf("fat_read_bpb: file: %s\n", f->filename);
	f->fo->read(f,NULL,100);
	strcpy(mp->param_and_control_block, f->filename);
}

struct file* fat_open(struct mount_point *mp, char *filename)
{
	struct file *mounted_f = mp->source;
	printf(" fat_open: mounted_f->filename: %s, type: %u, file to open:%s\n", 
				mounted_f->filename,mounted_f->type, filename);
	printf(" fat_open: params: %s\n", mp->param_and_control_block);

	struct file *newfile = &files[file_count++];
	newfile->type = FILESYSTEM;
	strcpy(newfile->filename,filename);
	newfile->base.mp = mp;
	newfile->fo = &fat_fo;
	
	return newfile;
}

int fat_read(struct file *f, char *buffer, int size)
{
	struct file *parent = f->base.mp->source;
	f->sector += size;

	printf (" fat_read: current: %s [type: %u] parent: %s [type: %u]",
			f->filename, f->type, parent->filename,
			parent->type);
	printf(" sector: %u\n", f->sector);

	return parent->fo->read(parent, buffer, size);
}
