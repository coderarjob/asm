
#ifndef _H_DEVFS
#define _H_DEVFS

#include "fs.h"

void register_devfs(struct device *device, struct file_operations *fo, char
					*device_name);
#endif // _H_DEVFS
