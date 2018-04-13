#include<linux/kernel.h>
#include<linux/syscalls.h>

asmlinkage void sys_mysyscall(char *str){
    printk("%s\n", str);
}

