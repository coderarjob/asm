
#ifndef _H_VFS
#define _H_VFS

	#include "fs.h"

void register_fs(struct filesystem *fs);
void mount(struct file *source, char *fsname, char *drive);
struct mount_point *get_mount_point(char *drive);
#endif // _H_VFS
