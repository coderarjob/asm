#include "devfs.h"
#include <stddef.h>
#include <stdio.h>


struct file *dev_open(struct mount_point *mp, char *filename);
int dev_read(struct file *f, char *buffer, int size);
int dev_config(struct file*, int getset, int key, int value);

struct file_operations dev_fo = {
	.open = dev_open,
	.read = dev_read,
	.config = dev_config

};

void device_init()
{
	struct device dev0 = {.devid = DEVICE(1,0)};
	struct device dev1 = {.devid = DEVICE(1,0)};
	printf("device_init: Registering devices.\n");
	register_devfs(&dev0,&dev_fo,"floppy0");
	register_devfs(&dev1,&dev_fo,"floppy1");
}

struct file *dev_open(struct mount_point *mp, char *filename)
{
	printf(" dev_open: %s, major = %u, minor = %u",
				mp->drive,
				MAJOR(mp->source->base.device),
				MINOR(mp->source->base.device));
	return NULL;
}

int dev_config(struct file *file, int getset, int key, int value)
{
	struct device *dev = &file->base.device;
	if (getset == CONFIG_GET)
		value = dev->device_parameters[key];
	else
		dev->device_parameters[key] = value;

	printf("floppy_config: key: %u, value %u\n",key, value);

	return (getset == CONFIG_GET)?value:0;

}

int dev_read(struct file *current_f, char *buffer, int size)
{
	current_f->sector += size;
	printf(" dev_read: %s, major = %u, minor = %u, sector: %u\n",
				current_f->filename,
				MAJOR(current_f->base.device),
				MINOR(current_f->base.device),
				current_f->sector);
}
