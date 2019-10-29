

#include "device.h"
#include "fs.h"
#include <string.h>	// strcpy
#include <stdlib.h> // malloc
#include <stdio.h>
#include "panic.h"
#include "devfs.h"
#include "vfs.h"

static struct file devices[10];
static int device_count;
struct file* devfs_open(struct mount_point *mp, char *filename);

struct file_operations devfs_fo = {
	.open = devfs_open,
};

struct filesystem devfs_fsi = {
	.fsname = "DEVFS",
	.fso = NULL,
	.fo = &devfs_fo
};

void devfs_init()
{
	printf("Registering devfs file system.\n");
	register_fs(&devfs_fsi);
}

void register_devfs(struct device *device, struct file_operations *fo, char
					*device_name)
{

	struct file *newfile = &devices[device_count++];
	newfile->type = DEVICE;
	strcpy(newfile->filename,device_name);
	memcpy(&newfile->base.device, device, sizeof(struct device));
	newfile->fo = fo;

	printf("register_devfs: Registering: %s\n", device_name);
}

struct file* devfs_open(struct mount_point *mp, char *filename)
{
	printf(" devfs_open: %s\n", filename);
	
	// Search for the deivce file
	struct file *f = NULL;
	for (int i = 0; i < device_count;i++)
	{
		struct file *tf = &devices[i];
		if (strcmp(tf->filename, filename) == 0){
			f = tf;
			break;
		}
	}

	if (f == NULL)
		panic("DEVICE not found",1);	

	// read 2 bytes
	f->fo->read(f,NULL,2);

	return f;
}
