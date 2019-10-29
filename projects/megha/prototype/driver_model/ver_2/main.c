#include <stdio.h>
#include "vfs.h"
#include "panic.h"

void devfs_init();
void device_init();
void fat_init();
struct file *open(char *filename);
void filename_split(char *filewithpath, char *drive, char *filetitle);

int main()
{
	device_init(); // register_devfs(DEVICE(1,0),&dev_fo,"floppy0");
	devfs_init();  // register_fs("devfs", &devfs_fsi);
	fat_init();    // register_fs("fat", &fat_fsi);

	mount(NULL,"DEVFS","d");
	struct file *f = open("d:/floppy0");
	f->fo->config(f,CONFIG_SET,1,100);
	f->fo->config(f,CONFIG_SET,2,500);
	printf("%u\n",f->type);
	/*struct file *f1 = open("d:/floppy1");
	f->fo->read(f,NULL,10);
	f1->fo->read(f1,NULL,5);

	printf("Use count devfs: %d\n",get_mount_point("d")->usecount);
	mount(f,"FAT","c");
	printf("Use count f1: %d, f: %d\n",f1->usecount, f->usecount);
	struct file *f2 = open("c:/images");
	f2->fo->read(f2,NULL,10);

	struct file *f1 = open("c:/images");
	mount(f1, "FAT", "i");

	struct file *f2 = open("i:/view");
	f2->fo->read(f2,NULL,10);*/
}

struct file *open(char *filename)
{
	char drive[5], filetitle[11];
	filename_split(filename, drive, filetitle);
	printf("Open: Drive: %s, Filetitle: %s\n", drive, filetitle);

	struct mount_point *mp = get_mount_point(drive);
	if (mp == NULL)
		panic("Drive was not found",3);
	else
		printf("Mount point %s found.\n",mp->drive);

	struct file *nf;
	if ((nf = mp->fs->fo->open(mp,filetitle)) != NULL)
		mp->usecount++;

	return nf;
}

void filename_split(char *filewithpath, char *drive, char *filetitle)
{
	char c;
	while ((c = *filewithpath++) != ':')
		*drive++ = c;
	*drive = '\0';	
	*filewithpath++;

	while ((c = *filewithpath++))
		*filetitle++ = c;
	
	*filetitle = '\0';
}
