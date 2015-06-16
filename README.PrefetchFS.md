# Use case: static compilation of PrefetchFS

PrefetchFS is a FUSE filesystem that caches and prefetches big media
files on-demand.  While a file is kept open by say, mplayer, we read
from the source (generally residing on an SSHFS) as fast as
possible and store everything in the prefetch directory.  The
prefetching tries to be clever and works well if you seek around in
the file.  Thanks to the prefetch/cache directory, when you're playing
a media file the second time, everything will be already cached.

The implementation language is Haskell, and we use the ghc-musl Docker
image to create an executable that is portable between all the
different amd64 based distros.

Let's get started!

## Building PrefetchFS with ghc-musl

```
brooks:/tmp $ docker run -v /tmp/x:/tmp/x -it --rm nilcons/ghc-musl
/ # cd /tmp
/tmp # git clone https://github.com/nilcons/PrefetchFS
Cloning into 'PrefetchFS'...
remote: Counting objects: 92, done.
remote: Total 92 (delta 0), reused 0 (delta 0), pack-reused 92
Unpacking objects: 100% (92/92), done.
Checking connectivity... done.
/tmp # cd PrefetchFS/
/tmp/PrefetchFS # cabal install --only-dependencies
Resolving dependencies...
All the requested packages are already installed:
Use --reinstall if you want to reinstall anyway.
```

We have started up a docker container and git cloned
the source code of PrefetchFS, then we tried to install all the
required Hackage packages, but we see that everything that PrefetchFS
needs is already included in ghc-musl.

So let's go ahead and compile it!

```
/tmp/PrefetchFS # cabal build
Package has never been configured. Configuring with default flags. If this
fails, please run configure manually.
Resolving dependencies...
Configuring PrefetchFS-0.1...
Building PrefetchFS-0.1...
Preprocessing executable 'PrefetchFS' for PrefetchFS-0.1...
[1 of 3] Compiling Common           ( Common.hs, dist/build/PrefetchFS/PrefetchFS-tmp/Common.o )
[2 of 3] Compiling PrefetchHandle   ( PrefetchHandle.hs, dist/build/PrefetchFS/PrefetchFS-tmp/PrefetchHandle.o )
[3 of 3] Compiling Main             ( PrefetchFS.hs, dist/build/PrefetchFS/PrefetchFS-tmp/Main.o )
Linking dist/build/PrefetchFS/PrefetchFS ...
/tmp/PrefetchFS # ls -l dist/build/PrefetchFS/PrefetchFS
-rwxr-xr-x    1 root     root       2021208 Jun 11 18:34 dist/build/PrefetchFS/PrefetchFS
/tmp/PrefetchFS # strip -s dist/build/PrefetchFS/PrefetchFS
/tmp/PrefetchFS # ls -l dist/build/PrefetchFS/PrefetchFS
-rwxr-xr-x    1 root     root       1304712 Jun 11 18:35 dist/build/PrefetchFS/PrefetchFS
```

The compiled size is 1.3M, but actually it's dynamically linked:
```
/tmp/PrefetchFS # ldd dist/build/PrefetchFS/PrefetchFS
    /lib/ld-musl-x86_64.so.1 (0x7f87d8b3f000)
    libfuse.so.2 => /usr/lib/libfuse.so.2 (0x7f87d8906000)
    libgmp.so.10 => /usr/lib/libgmp.so.10 (0x7f87d86a2000)
    libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f87d8b3f000)
```

That's not what we really want, so let's set up static linking:
```
/tmp/PrefetchFS # cabal clean
cleaning...
/tmp/PrefetchFS # echo '  ld-options: -static' >>PrefetchFS.cabal
/tmp/PrefetchFS # cabal build
Package has never been configured. Configuring with default flags. If this
fails, please run configure manually.
Resolving dependencies...
Configuring PrefetchFS-0.1...
Building PrefetchFS-0.1...
Preprocessing executable 'PrefetchFS' for PrefetchFS-0.1...
[1 of 3] Compiling Common           ( Common.hs, dist/build/PrefetchFS/PrefetchFS-tmp/Common.o )
[2 of 3] Compiling PrefetchHandle   ( PrefetchHandle.hs, dist/build/PrefetchFS/PrefetchFS-tmp/PrefetchHandle.o )
[3 of 3] Compiling Main             ( PrefetchFS.hs, dist/build/PrefetchFS/PrefetchFS-tmp/Main.o )
Linking dist/build/PrefetchFS/PrefetchFS ...
/usr/lib/gcc/x86_64-alpine-linux-musl/4.9.2/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lfuse
collect2: error: ld returned 1 exit status
```

The issue causing the linking error here is that there is no
`libfuse.a` archive in the `fuse-dev` package of Alpine Linux by
default.  When we dynamically link and use a C library, we are looking
for `libsomething.so`, for static linking we need a `libsomething.a`.

```
/tmp/PrefetchFS # ls -l /usr/lib/libfuse*
lrwxrwxrwx    1 root     root            16 Jun 11 16:11 /usr/lib/libfuse.so -> libfuse.so.2.9.4
lrwxrwxrwx    1 root     root            16 Jun 11 16:11 /usr/lib/libfuse.so.2 -> libfuse.so.2.9.4
-rwxr-xr-x    2 root     root        231448 May 25 10:08 /usr/lib/libfuse.so.2.9.4
```

So Alpine Linux out of the box only supports dynamic linking with
libfuse, not static linking.

## Modifying an Alpine package to be statically linked

This, of course, only affects us because we are using a C library
wrapper.  If PrefetchFS were implemented purely in Haskell, then none
of this would be necessary.  It is left as an exercise to the reader
to implement an HFuse replacement that talks the `/dev/fuse` protocol
directly without wrapping the libfuse C library.  When you are done,
please notify the author. :-)

Fortunately, libfuse is perfectly OK to statically link against.  For
more complicated libraries, like GTK or X11 recompiling everything
with static linking support may be a lot of work or might not be
possible at all, but for libfuse we will be fine.

```
/tmp/PrefetchFS # cd ..
/tmp # adduser -D build
/tmp # adduser build abuild
/tmp # chown root.abuild /var/cache/distfiles
/tmp # chmod 0775 /var/cache/distfiles
/tmp # echo 'build ALL=(ALL) NOPASSWD: ALL' >>/etc/sudoers
/tmp # su - build
a17c2500b8ef:~$ abuild-keygen -a -i
>>> Generating public/private rsa key pair for abuild
Enter file in which to save the key [/home/build/.abuild/build-5579d961.rsa]:
Generating RSA private key, 2048 bit long modulus
.............................................................+++
......+++
e is 65537 (0x10001)
writing RSA key
>>> Installing /home/build/.abuild/build-5579d961.rsa.pub to /etc/apk/keys...
>>>
>>> Please remember to make a safe backup of your private key:
>>> /home/build/.abuild/build-5579d961.rsa
>>>
a17c2500b8ef:~$ git clone https://github.com/alpinelinux/aports.git
Cloning into 'aports'...
remote: Counting objects: 204627, done.
remote: Compressing objects: 100% (28/28), done.
remote: Total 204627 (delta 12), reused 0 (delta 0), pack-reused 204596
Receiving objects: 100% (204627/204627), 113.20 MiB | 7.50 MiB/s, done.
Resolving deltas: 100% (124212/124212), done.
Checking connectivity... done.
a17c2500b8ef:~$ cd aports/main/fuse/
a17c2500b8ef:~/aports/main/fuse$ abuild -r
... (lots of output)
a17c2500b8ef:~/aports/main/fuse$ ls -l /home/build/packages/main/x86_64/
total 136
-rw-r--r--    1 build    build          900 Jun 11 18:55 APKINDEX.tar.gz
-rw-r--r--    1 build    build        98632 Jun 11 18:55 fuse-2.9.4-r0.apk
-rw-r--r--    1 build    build        31682 Jun 11 18:55 fuse-dev-2.9.4-r0.apk
```

Okay, it's a bit hairy to get an Alpine Linux into a state where it
can build packages, but we did it!  Yay!

Now to static linking:
```
a17c2500b8ef:~/aports/main/fuse$ sed -i s/disable-static/enable-static/i APKBUILD
```

Of course, this step requires investigation for every package, but for
fuse, the Alpine Linux guys simply disabled static linking.  I don't
know why, maybe to save on disk space.  We just have to re-enable it
and rebuild the library:

```
a17c2500b8ef:~/aports/main/fuse$ abuild clean
>>> fuse: Cleaning temporary build dirs...
a17c2500b8ef:~/aports/main/fuse$ abuild -r
... (lots of output again)
a17c2500b8ef:~/aports/main/fuse$ sudo apk add /home/build/packages/main/x86_64/fuse-*
(1/2) Replacing fuse (2.9.4-r0 -> 2.9.4-r0)
(2/2) Replacing fuse-dev (2.9.4-r0 -> 2.9.4-r0)
Executing busybox-1.23.2-r0.trigger
OK: 781 MiB in 360 packages
a17c2500b8ef:~/aports/main/fuse$ ls -l /usr/lib/libfuse*
-rw-r--r--    1 root     root        351138 Jun 11 18:58 /usr/lib/libfuse.a
lrwxrwxrwx    1 root     root            16 Jun 11 18:58 /usr/lib/libfuse.so -> libfuse.so.2.9.4
lrwxrwxrwx    1 root     root            16 Jun 11 18:58 /usr/lib/libfuse.so.2 -> libfuse.so.2.9.4
-rwxr-xr-x    1 root     root        231448 Jun 11 18:58 /usr/lib/libfuse.so.2.9.4
```

Huge success!

## Finishing up

We can try building PrefetchFS again:

```
/tmp # cd PrefetchFS/
/tmp/PrefetchFS # cabal build
Package has never been configured. Configuring with default flags. If this
fails, please run configure manually.
Resolving dependencies...
Configuring PrefetchFS-0.1...
Building PrefetchFS-0.1...
Preprocessing executable 'PrefetchFS' for PrefetchFS-0.1...
[1 of 3] Compiling Common           ( Common.hs, dist/build/PrefetchFS/PrefetchFS-tmp/Common.o )
[2 of 3] Compiling PrefetchHandle   ( PrefetchHandle.hs, dist/build/PrefetchFS/PrefetchFS-tmp/PrefetchHandle.o )
[3 of 3] Compiling Main             ( PrefetchFS.hs, dist/build/PrefetchFS/PrefetchFS-tmp/Main.o )
Linking dist/build/PrefetchFS/PrefetchFS ...
/tmp/PrefetchFS # strip -s dist/build/PrefetchFS/PrefetchFS
/tmp/PrefetchFS # file dist/build/PrefetchFS/PrefetchFS
dist/build/PrefetchFS/PrefetchFS: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, stripped
/tmp/PrefetchFS # ldd dist/build/PrefetchFS/PrefetchFS
ldd: dist/build/PrefetchFS/PrefetchFS: Not a valid dynamic program
/tmp/PrefetchFS # ls -l dist/build/PrefetchFS/PrefetchFS
-rwxr-xr-x    1 root     root       1874200 Jun 13 17:57 dist/build/PrefetchFS/PrefetchFS
```

1.8M and fully statically linked, successfully tested on various
versions of Debian and Ubuntu.

We just wanted to have the executable in hand, so we used the `/tmp/x`
docker volume to pass out the end result to the host system.

If you are doing this for a real production executable, you can create
a Dockerfile with the build steps, and you have a reproducible static build!

## Alternative to static linking

An alternative way would be to accept the fact that we have to link
dynamically because of the missing `libfuse.a` and use the same
distribution strategy as in [case of nc-indicator](README.nc-indicators.md).

## Nasty bug in LibFFI

While writing up this tutorial, we've hit a very tricky and complicated
bug in LibFFI.  Our musl based GHC was generating broken code when a C
FFI function called back into Haskell land and things just segfaulted
at that point.  It was a very interesting debugging session, including
disassembling and gdbing a Haskell binary, lots of fun!
