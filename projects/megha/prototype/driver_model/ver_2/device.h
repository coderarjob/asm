

#ifndef _H_DEVICE
#define _H_DEVICE
	
#include<stdint.h> 
typedef uint16_t device_t;

struct device 
{
	device_t devid;
	int device_parameters[50];
};

#define DEVICE(m,n) (((m) << 8) | (n))
#define MAJOR(d) ((d.devid >> 8) & 0xFF)
#define MINOR(d) (d.devid & 0xFF)

#endif // _H_DEVICE
