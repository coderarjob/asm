

#ifndef _H_FILE
#define _H_FILE

#include "device.h"

typedef enum {DEVICE, FILESYSTEM} file_t;
#define CONFIG_GET 0
#define CONFIG_SET 1

struct file
{
	file_t type;
	char filename[10];
	union{
		struct device device;
		struct mount_point *mp;
	} base;
	struct file_operations *fo;
	int usecount;
	int sector;
};

struct mount_point
{
	char drive[10];
	struct file *source;
	struct filesystem *fs;
	int usecount;
	char param_and_control_block[100];
};

struct file_operations
{
	struct file *(*open)(struct mount_point *mp, char *filename);
	int (*read)(struct file*, char *buffer, int size);
	int (*config)(struct file*, int getset, int key, int value);
};

struct filesystem_operations
{
	int (*read_bpb)(struct file *f, struct mount_point *mp);
	int (*format)(struct file *f);
};

struct filesystem
{
	char fsname[10];
	struct filesystem_operations *fso;
	struct file_operations *fo;
};
#endif // _H_FILE
