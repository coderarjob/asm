
#include "fs.h"
#include "vfs.h"
#include <string.h>
#include "panic.h"

static struct mount_point mounts[10];
static int mount_counts;

static struct filesystem fses[10] = {0};
static int count;

void register_fs(struct filesystem *fs)
{
	struct filesystem *newfs = &fses[count++];	
	memcpy(newfs, fs, sizeof(struct filesystem));

	printf("register_fs: Registering file system: %s\n", fs->fsname);
}

void mount(struct file *source, char *fsname, char *drive)
{
	// Search for the particular file system
	struct filesystem *fs = NULL;
	for(int i = 0; i < count; i++)
	{
		struct filesystem *_fs = &fses[i];
		if (strcmp(_fs->fsname, fsname) == 0)
		{
			fs = _fs;
			break;
		}
	}

	if (fs == NULL)
		panic("File system not found",2);

	struct mount_point *mp = &mounts[mount_counts++];
	mp->fs = fs;
	mp->source = source;
	strcpy(mp->drive,drive);

	if (source != NULL)
		source->usecount++;

	if(fs->fso != NULL && fs->fso->read_bpb != NULL)
		fs->fso->read_bpb(source,mp);
	printf("mount: mounted filesystem: %s into drive %s\n",fs->fsname,drive);
}

struct mount_point *get_mount_point(char *drive)
{
		
	// Search for the particular mount point
	struct mount_point *mp = NULL;
	for(int i = 0; i < mount_counts; i++)
	{
		struct mount_point *_mp = &mounts[i];
		if (strcmp(_mp->drive,drive) == 0)
		{
			mp = _mp;
			break;
		}
	}

	return mp;
}
