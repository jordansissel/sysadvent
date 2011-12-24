Down The Rabbit Hole
====================

_This article was written by [Adam Fletcher](http://www.thesimplelogic.com/) ([@adamfblahblah](http://twitter.com/adamfblahblah))_

From `ls(1)` to the kernel and back again.  
----------------------------------------

Too often sysadmins are afraid to dive into the source code of our core
utilities to see how they really work. We're happy to edit our scripts but we
don't do the same with our command line utilities, libraries, and
kernel.  Today we're going to do some source diving in
those core components. We'll answer the age-old interview question, "What
happens when you type `ls` at the command line and press enter?" The answer to this question
has infinite depth, so I'll leave out some detail, but I'll capture the essence
of what is going, and I'll show the source in each component as we go. The
pedants in the crowd may find much to gripe about but hopefully they'll do so
by posting further detail in the comments. 

Requirements
------------

It'll be helpful if you install the source on your machine for the software
we'll be looking at. Below are the commands I used to get the source for the
needed packages on Ubuntu 9.10, and similar packages are available for your
Linux distribution. 

    apt-get install linux-source 
    apt-get source coreutils 
    apt-get source bash
    apt-get source libc6
    apt-get install manpages-dev 

I'm using `linux-source` version `2.6.31.22.35`, `coreutils` (for the code to
`ls`) version `7.4-2ubuntu1`, `bash` version `3.5.21`, and `libc6` version
`2.10.1-0ubuntu18`, and finally `manpages-dev` to get the programmer's `man` pages.


Starting Out - `strace` & `bash`
--------------------------------

One of the most useful tools in the sysadmin's arsenal is `strace`, a command
that will show you most of the standard library and system calls a program
makes while it executes. We'll use this tool extensively to figure out what
code we are looking for in each component. 

Let's start by `strace`'ing `bash` when it runs `ls`. To do so, we'll start a
new instance of `bash` under `strace`. Note that I'll be cutting the output of
`strace` down a lot in the post for readability.

    adamf@kid-charlemagne:~/foo$ strace bash
    execve("/bin/bash", ["bash"], [/* 30 vars */]) = 0

    [... wow that's a lot of output ...]

    write(2, "adamf@kid-charlemagne:~/foo$ ", 29adamf@kid-charlemagne:~/foo$ ) = 29
    rt_sigprocmask(SIG_SETMASK, [], NULL, 8) = 0
    rt_sigprocmask(SIG_BLOCK, NULL, [], 8)  = 0
    read(0, 

... and that's where the output stops. If you're new to `strace` the key to
reading it is to make liberal use of `man` pages to figure out what each
library call does. Be aware that the relevant pages you want are in section
2 of the `man` pages, so you'll need to do `man 2 read` to find the page on `read`; this is
because many of the system functions have the same name as regular commands that are found
in chapter 1 of the `man` pages.

The `read` call is waiting for input on file descriptor 0, which is standard
input. So we type `ls` and hit enter (you'll see more `read` & `write` calls as
you type). 

There's a lot of output, but we know we want to see `ls` related output, so
let's do the simple thing and look at the lines that have `ls` in them:

    stat("/usr/local/sbin/ls", 0x7fff03f1fd60) = -1 ENOENT (No such file or directory)
    stat("/usr/local/bin/ls", 0x7fff03f1fd60) = -1 ENOENT (No such file or directory)
    stat("/usr/sbin/ls", 0x7fff03f1fd60)    = -1 ENOENT (No such file or directory)
    stat("/usr/bin/ls", 0x7fff03f1fd60)     = -1 ENOENT (No such file or directory)
    stat("/sbin/ls", 0x7fff03f1fd60)        = -1 ENOENT (No such file or directory)
    stat("/bin/ls", {st_mode=S_IFREG|0755, st_size=114032, ...}) = 0
    stat("/bin/ls", {st_mode=S_IFREG|0755, st_size=114032, ...}) = 0

If we `man 2 stat` we see that `stat` returns information about a file if it
can find it, and an error if it can't (much more on `stat` later). In this case
what `bash` is doing is searching my `$PATH` environment variable in hopes of
finding an executable file with the name `ls`. Bash will `stat` every directory
in my `$PATH`, and if it can't find the file it returns `command not found`. In
this case, Bash found `ls` in `/bin`, and then that's the last we see of the
string `ls` in our output. 

We don't see `ls` in our output anymore because once Bash knows it can execute
the program it spawns a child process to execute that program, and we haven't 
told `strace` to follow children of the command it is tracing.  It's the next
few lines of `strace` that give this spawning away: 

    pipe([3, 4])                            = 0
    clone(child_stack=0, flags=CLONE_CHILD_CLEARTID|CLONE_CHILD_SETTID|SIGCHLD, child_tidptr=0x7f2c853217c0) = 30125

If we `man 2 pipe` and `man 2 clone` we see that `bash` is creating a pipe (two
file descriptors that can be read and written to; this way a shell can link commands input 
and output together when you give the shell a `|` character) and `clone`'ing itself so
that there are two copies of `bash` running. Remember, every UNIX process is a
child of another process, and a brand new process starts out as a copy of its
parent. So when does ls actually happen? Let's `strace ls` and find out!

    adamf@kid-charlemagne:~/foo$ strace ls
    execve("/bin/ls", ["ls"], [/* 30 vars */]) = 0

That first line is the key. `execve` is the library call to load and run a new
executable. Once `execve` runs we're actually `ls` (well, the loader runs
first, but that's another article). Interestingly, the call to `execve` is in
the `bash` source code, not the `ls` source code. Let's find it in the `bash`
code:

    adamf@kid-charlemagne:/usr/src/bash-4.0/bash-4.0$ find . | xargs grep -n "execve ("
    ./builtins/exec.def:201:  shell_execve (command, args, env);
    ./execute_cmd.c:4323:   5) execve ()
    ./execute_cmd.c:4466:      exit (shell_execve (command, args, export_env));
    ./execute_cmd.c:4577:  return (shell_execve (execname, args, env));
    ./execute_cmd.c:4653:/* Call execve (), handling interpreting shell scripts, and handling
    ./execute_cmd.c:4656:shell_execve (command, args, env)
    ./execute_cmd.c:4665:  execve (command, args, env);


If we look at line 4323 in `execute_cmd.c` we see this helpful comment:

    /* Execute a simple command that is hopefully defined in a disk file
    somewhere.

    1) fork ()
    2) connect pipes
    3) look up the command
    4) do redirections
    5) execve ()
    6) If the execve failed, see if the file has executable mode set.
    If so, and it isn't a directory, then execute its contents as
    a shell script.
    [...]
    */

And looking at line 4665 we do see the call to `execve`. Take a look at the code
around `execve` - it's a bunch of error handling but nothing too hard to
understand. What's interesting is what is not there; the code exists only to
handle errors and nothing to handle success. That is because `execve` will only
return if there's a failure, which makes sense - a successful call to `execve`
means we're running something completely different!

Look around `execute_cmd.c` at the code around calls to `shell_execve` and
you'll see that that code is fairly straightforward.

Inside `ls(1)`
------------

Let's look at what `ls` is doing by creating a single file in our directory and
`ls`'ing that file under `strace`.

    adamf@kid-charlemagne:~/foo$ touch bar
    adamf@kid-charlemagne:~/foo$ strace ls bar
    execve("/bin/ls", ["ls", "bar"], [/* 30 vars */]) = 0

Interesting! We can see that `bar` is now being passed to our `execve` call.
Let's keep looking at the `strace` output to find `bar`:

    stat("bar", {st_mode=S_IFREG|0644, st_size=0, ...}) = 0
    lstat("bar", {st_mode=S_IFREG|0644, st_size=0, ...}) = 0
    fstat(1, {st_mode=S_IFCHR|0620, st_rdev=makedev(136, 0), ...}) = 0
    mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7f467abbe000
    write(1, "bar\n", 4bar
    )                    = 4

Right at the end of the `strace` output we see `bar` a few times. It looks like
`bar` gets passed to `stat`, `lstat`, and `write`. Working backwards, we can `man 2 write` 
to figure out that `write` sends data to a file descriptor, in this case
standard out, which is our screen. So the call to `write` is just `ls` printing out
`bar`. The next two library calls, `stat` and `lstat`, share a `man` page, with the
difference between the commands being that `lstat` will get information on a
symbolic link while `stat` will only get information on a file. Let's look in in
the `ls` source code for these calls to see why `ls` does both `lstat` and `stat`:

    adamf@kid-charlemagne:/usr/src/coreutils-7.4/src$ grep -n "stat (" ls.c
    967:      assert (0 <= stat (Name, &sb));       \
    2437:      ? fstat (fd, &dir_stat)
    2438:      : stat (name, &dir_stat)) < 0)
    2721:     err = stat (absolute_name, &f->stat);
    2730:         err = stat (absolute_name, &f->stat);
    2749:     err = lstat (absolute_name, &f->stat);
    2837:         && stat (linkname, &linkstats) == 0)

That call to `lstat` stands out amongst the other calls, and so it is a pretty
good guess that `lstat` happens for some exceptional reason that programmer would
notate with a comment. Looking at line 2749 in `ls.c` we see an interesting
comment a few lines above:

             /* stat failed because of ENOENT, maybe indicating a dangling
                 symlink.  Or stat succeeded, ABSOLUTE_NAME does not refer to a
                 directory, and --dereference-command-line-symlink-to-dir is
                 in effect.  Fall through so that we call lstat instead.  */
            }

        default: /* DEREF_NEVER */
          err = lstat (absolute_name, &f->stat);
          do_deref = false;
          break;
        }

That comment means that if we're not talking about a directory and `stat` has
already succeeded, we need to see if we are looking at a symlink.  We can see
that this is true by `ls`'ing a directory under `strace`:

    adamf@kid-charlemagne:~/foo$ strace ls /home/adamf/foo/
    [...]
    stat("/home/adamf/foo/", {st_mode=S_IFDIR|0755, st_size=4096, ...}) = 0
    open("/home/adamf/foo/", O_RDONLY|O_NONBLOCK|O_DIRECTORY|O_CLOEXEC) = 3
    fcntl(3, F_GETFD)                       = 0x1 (flags FD_CLOEXEC)
    getdents(3, /* 3 entries */, 32768)     = 72
    getdents(3, /* 0 entries */, 32768)     = 0
    close(3)                                = 0
    fstat(1, {st_mode=S_IFCHR|0620, st_rdev=makedev(136, 0), ...}) = 0
    mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7f873dda4000
    write(1, "bar\n", 4bar

Note that there was no call to `lstat` this time. 

Where We Are Going There Is No `strace`
---------------------------------------

It is time to bid our friend `strace` a fond farewell as he doesn't have what
it takes to show us what `stat` is doing. For that we need to look into the
standard library, or as it is commonly known, `libc`. 

The `libc` code provides a common API for UNIX programs, and a portion of that
API is the system calls. These are functions that provide a way for a
programmer to ask the kernel for a resource that is managed by the kernel,
including the resource we're interested in: the filesystem. The code we'd like
to look at is for the system call `stat`. However, because kernels are very
dependent on the hardware architecture they run on, and `libc` needs to talk to
the kernel, much of the code you'll find in the `libc` source organized by
architecture. This makes finding the code for `stat` tricky; if we look in
`io/stat.c` we see basically a single line of code that calls a function called
`__xstat`. If we `find . -name xstat.c` we'll see that we want
`./sysdeps/unix/sysv/linux/i386/xstat.c`, which is the implementation of `stat` for
Linux on i386. 

The code in `xstat.c` that isn't a reference to a C `#include` looks like:

    return INLINE_SYSCALL (stat, 2, CHECK_STRING (name), CHECK_1 ((struct kernel_stat *) buf));

And:

    result = INLINE_SYSCALL (stat64, 2, CHECK_STRING (name), __ptrvalue (&buf64));

Reading the comments in the code we can see that `stat64`is for 64-bit
platforms. We'll stick to 32-bits for now, but either way we need to figure out
what `INLINE_SYSCALL` is. A convention in C programming is that FUNCTIONS IN ALL
CAPS are pre-processor macros, which means you can typically find out what
those macros are by `grep`'ing for `define <macroname>`:

    adamf@kid-charlemagne:/usr/src/eglibc-2.10.1/sysdeps/unix/sysv/linux/i386$ grep -n "define INLINE_SYSCALL" *
    sysdep.h:348:#define INLINE_SYSCALL(name, nr, args...) \


At first, the code we find at line 348 in `sysdep.h` looks confusing:

    #define INLINE_SYSCALL(name, nr, args...) \
    ({                                                                          \
        unsigned int resultvar = INTERNAL_SYSCALL (name, , nr, args);             \
        if (__builtin_expect (INTERNAL_SYSCALL_ERROR_P (resultvar, ), 0))         \
        {                                                                       \
            __set_errno (INTERNAL_SYSCALL_ERRNO (resultvar, ));                   \
            resultvar = 0xffffffff;                                               \
        }                                                                       \
        (int) resultvar; })

Looking at the code the call to `INTERNAL_SYSCALL` stands out - it appears that
all `INLINE_SYSCALL` is doing is calling `INTERNAL_SYSCALL`. Conveniently we can
scroll down in `sysdep.h` to find the definition of `INTERNAL_SYSCALL`:

    /* Define a macro which expands inline into the wrapper code for a system
    call.  This use is for internal calls that do not need to handle errors
    normally.  It will never touch errno.  This returns just what the kernel
    gave back.

    The _NCS variant allows non-constant syscall numbers but it is not
    possible to use more than four parameters.  */
    #undef INTERNAL_SYSCALL
    #ifdef I386_USE_SYSENTER
    # ifdef SHARED
    #  define INTERNAL_SYSCALL(name, err, nr, args...) \

... but it appears to define `INTERNAL_SYSCALL` a few times, and I'm not sure
which one is actually used. 

A good practice in a situation like this is to stop looking at the code and
instead take some time to understand the concept the code is trying to
implement. Googling for something like `i386 system calls linux` gets us a to
(Implementing A System Call On i386 Linux)[http://tldp.org/HOWTO/html_single/Implement-Sys-Call-Linux-2.6-i386/] which
says:

    A system call executes in the kernel mode. Every system call has a number
    associated with it. This number is passed to the kernel and that's how the
    kernel knows which system call was made. When a user program issues a system
    call, it is actually calling a library routine. The library routine issues a
    trap to the Linux operating system by executing INT 0x80 assembly instruction.
    It also passes the system call number to the kernel using the EAX register. The
    arguments of the system call are also passed to the kernel using other
    registers (EBX, ECX, etc.). The kernel executes the system call and returns the
    result to the user program using a register. If the system call needs to supply
    the user program with large amounts of data, it will use another mechanism
    (e.g., copy_to_user call).


Okay, so I think the implementation of `INTERNAL_SYSCALL` we'll want will have `0x80` in it 
and some assembly code that puts stuff in the `eax` register (newer x86 machines can 
use `sysenter` instead of `int 0x80` to make syscalls). 
Line 419 in `sysdep.h` does the trick:

    # define INTERNAL_SYSCALL(name, err, nr, args...) \
    ({                                                                          \
        register unsigned int resultvar;                                          \
        EXTRAVAR_##nr                                                             \
        asm volatile (                                                            \
        LOADARGS_##nr                                                             \
        "movl %1, %%eax\n\t"                                                      \
        "int $0x80\n\t"                                                           \
        RESTOREARGS_##nr                                                          \
        : "=a" (resultvar)                                                        \
        : "i" (__NR_##name) ASMFMT_##nr(args) : "memory", "cc");                  \
        (int) resultvar; })

If we go back to `xstat.c` we see that the `name` we pass to `INTERNAL_SYSCALL` is
`stat`, and in the code above the `name` argument will expand from  `__NR_##name`
to `__NR_stat`. The web page we found describing syscalls says that syscalls are
represented by a number, so there has to be some piece of code that turns `__NR_stat` into a
number. However, when I `grep` through all of the `libc6` source I can't find any
definition of `__NR_stat` for i386. 

It turns out that the code that translates `__NR_stat` into a number is inside
the Linux kernel:

    adamf@kid-charlemagne:/usr/src/linux-source-2.6.31$ find . | grep x86 | xargs grep -n "define __NR_stat"
    ./arch/x86/include/asm/unistd_64.h:23:#define __NR_stat             4
    ./arch/x86/include/asm/unistd_64.h:309:#define __NR_statfs              137
    ./arch/x86/include/asm/unistd_32.h:107:#define __NR_statfs       99
    ./arch/x86/include/asm/unistd_32.h:114:#define __NR_stat        106
    ./arch/x86/include/asm/unistd_32.h:203:#define __NR_stat64      195
    ./arch/x86/include/asm/unistd_32.h:276:#define __NR_statfs64        268

The Amulet Of Yendor: Inside The Kernel
---------------------------------------

The syscall number definitions being inside the kernel makes sense, as the kernel is 
the owner of the syscall API and as such
will have the final say on what numbers get assigned to each syscall. As we're
running on 32-bit Linux, it appears the syscall number that `libc` is going to
put in `eax` is `106`. 

The table in `unistd_32.h` is great (look at all those syscalls!) but it
doesn't tell us where the code for handling a call to stat actually lives in
the kernel.  `find` is our friend again:

    adamf@kid-charlemagne:/usr/src/linux-source-2.6.31$ find . -name stat.c
    ./fs/stat.c
    ./fs/proc/stat.c

Well that was easy. Opening up `fs/stat.c` we find what we're looking for:

    SYSCALL_DEFINE2(stat, char __user *, filename, struct __old_kernel_stat __user *, statbuf)
    {
            struct kstat stat;
            int error;

            error = vfs_stat(filename, &stat);
            if (error)
                    return error;

            return cp_old_stat(&stat, statbuf);
    }


Looks like this just a wrapper around `vfs_stat`, which is also in `stat.c` and
is a wrapper around `vfs_statat`, which again is in `stat.c` and is wrapper
around two functions, `user_path_at()` and `vfs_getattr()`. We'll ignore `user_path_at()` 
for now (it figures out if the file exists) and instead follow
`vfs_getattr()`:

    int vfs_getattr(struct vfsmount *mnt, struct dentry *dentry, struct kstat *stat)
    {
            struct inode *inode = dentry->d_inode;
            int retval;

            retval = security_inode_getattr(mnt, dentry);
            if (retval)
                    return retval;

            if (inode->i_op->getattr)
                    return inode->i_op->getattr(mnt, dentry, stat);

            generic_fillattr(inode, stat);
            return 0;
    }


One thing that is helpful to do in a case like is to look back at any
documentation I have on the function whose implementation I'm tracking down,
which in this case is the library call to `stat`. Back to `man 2 stat` we see:

       All of these system calls return a stat structure, which contains the following fields:

           struct stat {
               dev_t     st_dev;     /* ID of device containing file */
               ino_t     st_ino;     /* inode number */
               mode_t    st_mode;    /* protection */
               nlink_t   st_nlink;   /* number of hard links */
               uid_t     st_uid;     /* user ID of owner */
               gid_t     st_gid;     /* group ID of owner */
               dev_t     st_rdev;    /* device ID (if special file) */
               off_t     st_size;    /* total size, in bytes */
               blksize_t st_blksize; /* blocksize for file system I/O */
               blkcnt_t  st_blocks;  /* number of 512B blocks allocated */
               time_t    st_atime;   /* time of last access */
               time_t    st_mtime;   /* time of last modification */
               time_t    st_ctime;   /* time of last status change */
           };

So our `vfs_getattr` function is trying to fill out these fields, which must be in the `struct kstat *stat` argument to `vfs_getattr`.
`vfs_getattr` tries to fill out the `stat` struct in two ways: 


        if (inode->i_op->getattr)
                return inode->i_op->getattr(mnt, dentry, stat);

        generic_fillattr(inode, stat);


In the first attempt to fill `stat`, `vfs_getattr` checks to see if this
`inode` struct has a special function defined to fill the `stat` structure.
Each `inode` has an `i_op` struct which can have a `getattr` function, if
needed. This `getattr` function is not defined in `fs.h` but rather is defined
by the specific file system the `inode` is on. This makes good sense as it
allows the application programmer to call `libc`'s `stat` without caring if the
underlying file system is ext2, ext3, NTFS, NFS, etc. This abstraction layer
is called the 'Virtual File System' and is why the syscall above is prefixed with 'vfs'.

Some filesystems, like NFS, implement a specific `getattr` handler, but the
filesystem I'm running (ext3) does not. In the case where there is no special
`getattr` function defined `vfs_getattr` will call `generic_fillattr`
(helpfully defined in `stat.c`) which simply copies the relevant data from the
`inode` struct to the `stat` struct:

    void generic_fillattr(struct inode *inode, struct kstat *stat)
    {
            stat->dev = inode->i_sb->s_dev;
            stat->ino = inode->i_ino;
            stat->mode = inode->i_mode;
            stat->nlink = inode->i_nlink;
            stat->uid = inode->i_uid;
            stat->gid = inode->i_gid;
            stat->rdev = inode->i_rdev;
            stat->atime = inode->i_atime;
            stat->mtime = inode->i_mtime;
            stat->ctime = inode->i_ctime;
            stat->size = i_size_read(inode);
            stat->blocks = inode->i_blocks;
            stat->blksize = (1 << inode->i_blkbits);
    }

If you squint a little bit at this struct you'll see all the fields you can get
out of a single `ls` command! Our adventure into the kernel has yielded fruit. 

Just One More Turn...
---------------------

If you'd like to keep going, the next thing to figure out is how the `inode`
struct gets populated (hint: `ext3_iget`) and updated, and from there figure
out how the kernel reads that data from the block device (and then how the
block device talks to the disk controller, and how the disk controller finds
the data on the disk, and so on).

I hope this has been instructive. Digging through the actual source code to a
program isn't as easy as reading a summary of how something works, but it is
more rewarding and you'll know how the program *actually* works. Don't be
intimidated by an unknown language or concept! We found our way through the
internals of the kernel with `strace`, `find` and `grep`, tools a sysadmin uses
every day.  

Other Resources
---------------

* /Documentation in the Linux kernel source
* The 2nd section of the Linux man pages
* [Implementing a System Call on Linux 2.6 for i386](http://tldp.org/HOWTO/html_single/Implement-Sys-Call-Linux-2.6-i386/)
