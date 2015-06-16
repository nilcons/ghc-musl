# Use case: portable deployment of dynamically compiled nc-indicators

[nc-indicators](https://github.com/nilcons/nc-indicators) is a tray
applet for X11 based GNU/Linux systems that shows the current CPU and
memory consumption of the system.  Since it's a tray applet you can
use it with any panel (e.g. gnome-panel, i3bar, lxpanel) and you don't
have to depend on the panel's own solution.

As it's a graphical GTK app and the implementation language is
Haskell, we use the ghc-musl Docker image to create an executable which
though dynamically linked, has the dependent `.so` files under the
same directory as the executable, and thus the whole package can be
distrubuted as a tar.gz.

## Building nc-indicators with ghc-musl

```
brooks:/tmp $ docker run -v /tmp/x:/tmp/x -it --rm nilcons/ghc-musl
/ # cd /tmp
/tmp # git clone https://github.com/nilcons/nc-indicators
Cloning into 'nc-indicators'...
remote: Counting objects: 52, done.
remote: Total 52 (delta 0), reused 0 (delta 0), pack-reused 52
Unpacking objects: 100% (52/52), done.
Checking connectivity... done.
/tmp # cd nc-indicators/
/tmp/nc-indicators # cabal install --only-dependencies
Resolving dependencies...
All the requested packages are already installed:
Use --reinstall if you want to reinstall anyway.
```

We have started up a docker container and git cloned the source code
of nc-indicators, then we tried to install all the required Hackage
packages, but we see that everything that nc-indicators needs is
already included in ghc-musl.

So let's go ahead and compile it!

```
/tmp/nc-indicators # cabal build
Package has never been configured. Configuring with default flags. If this
fails, please run configure manually.
Resolving dependencies...
Configuring nc-indicators-0.3...
Building nc-indicators-0.3...
(... lot of build warnings, someone should maybe fix those...)
Linking dist/build/nc-indicators/nc-indicators ...
/tmp/nc-indicators # strip -s dist/build/nc-indicators/nc-indicators
/tmp/nc-indicators # ls -l dist/build/nc-indicators/nc-indicators
-rwxr-xr-x    1 root     root      10053264 Jun 15 11:38 dist/build/nc-indicators/nc-indicators
/tmp/nc-indicators # ldd dist/build/nc-indicators/nc-indicators
/lib/ld-musl-x86_64.so.1 (0x7f895e94c000)
libgthread-2.0.so.0 => /usr/lib/libgthread-2.0.so.0 (0x7f895e74a000)
libgtk-x11-2.0.so.0 => /usr/lib/libgtk-x11-2.0.so.0 (0x7f895e181000)
libgdk-x11-2.0.so.0 => /usr/lib/libgdk-x11-2.0.so.0 (0x7f895dede000)
libpangocairo-1.0.so.0 => /usr/lib/libpangocairo-1.0.so.0 (0x7f895dcd1000)
libatk-1.0.so.0 => /usr/lib/libatk-1.0.so.0 (0x7f895daad000)
libcairo.so.2 => /usr/lib/libcairo.so.2 (0x7f895d7c6000)
libgdk_pixbuf-2.0.so.0 => /usr/lib/libgdk_pixbuf-2.0.so.0 (0x7f895d5aa000)
libgio-2.0.so.0 => /usr/lib/libgio-2.0.so.0 (0x7f895d254000)
libpangoft2-1.0.so.0 => /usr/lib/libpangoft2-1.0.so.0 (0x7f895d040000)
libpango-1.0.so.0 => /usr/lib/libpango-1.0.so.0 (0x7f895cdfc000)
libgobject-2.0.so.0 => /usr/lib/libgobject-2.0.so.0 (0x7f895cbbc000)
libglib-2.0.so.0 => /usr/lib/libglib-2.0.so.0 (0x7f895c8af000)
libintl.so.8 => /usr/lib/libintl.so.8 (0x7f895c6a5000)
libfontconfig.so.1 => /usr/lib/libfontconfig.so.1 (0x7f895c46e000)
libfreetype.so.6 => /usr/lib/libfreetype.so.6 (0x7f895c1d8000)
libz.so.1 => /lib/libz.so.1 (0x7f895bfc2000)
libgmp.so.10 => /usr/lib/libgmp.so.10 (0x7f895bd5e000)
libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f895e94c000)
libgmodule-2.0.so.0 => /usr/lib/libgmodule-2.0.so.0 (0x7f895bb5a000)
libX11.so.6 => /usr/lib/libX11.so.6 (0x7f895b835000)
libXfixes.so.3 => /usr/lib/libXfixes.so.3 (0x7f895b62f000)
libXrender.so.1 => /usr/lib/libXrender.so.1 (0x7f895b425000)
libXEasterEgg.so.6 => /usr/lib/libXEasterEgg.so.6 (0x7f895b216000)
libXrandr.so.2 => /usr/lib/libXrandr.so.2 (0x7f895b00c000)
libXcursor.so.1 => /usr/lib/libXcursor.so.1 (0x7f895ae02000)
libXcomposite.so.1 => /usr/lib/libXcomposite.so.1 (0x7f895abff000)
libXdamage.so.1 => /usr/lib/libXdamage.so.1 (0x7f895a9fc000)
libXext.so.6 => /usr/lib/libXext.so.6 (0x7f895a7eb000)
libharfbuzz.so.0 => /usr/lib/libharfbuzz.so.0 (0x7f895a5a4000)
libpixman-1.so.0 => /usr/lib/libpixman-1.so.0 (0x7f895a30d000)
libpng16.so.16 => /usr/lib/libpng16.so.16 (0x7f895a0df000)
libxcb-shm.so.0 => /usr/lib/libxcb-shm.so.0 (0x7f8959edb000)
libxcb-render.so.0 => /usr/lib/libxcb-render.so.0 (0x7f8959cd1000)
libxcb.so.1 => /usr/lib/libxcb.so.1 (0x7f8959ab1000)
libffi.so.6 => /usr/lib/libffi.so.6 (0x7f89598ac000)
libexpat.so.1 => /usr/lib/libexpat.so.1 (0x7f895968b000)
libgraphite2.so.3 => /usr/lib/libgraphite2.so.3 (0x7f8959473000)
libXau.so.6 => /usr/lib/libXau.so.6 (0x7f895926f000)
libXdmcp.so.6 => /usr/lib/libXdmcp.so.6 (0x7f8959069000)
```

The compiled size is 9.6M and it depends on a lot of libraries, as GTK
based stuff always do. :(

## Using patchelf to create a standalone deployment

```
/tmp/nc-indicators # mkdir deploy
cp -av dist/build/nc-indicators/nc-indicators deploy
'dist/build/nc-indicators/nc-indicators' -> 'deploy/nc-indicators'
/tmp/nc-indicators # cd deploy
/tmp/nc-indicators/deploy # mkdir lib
/tmp/nc-indicators/deploy # for f in $(ldd nc-indicators  | fgrep '=>' | awk '{print $3}') ; do cp -L $f lib/ ; done
/tmp/nc-indicators/deploy # patchelf --set-interpreter lib/ld-musl-x86_64.so.1 nc-indicators
/tmp/nc-indicators/deploy # patchelf --set-rpath '$ORIGIN/lib' nc-indicators
/tmp/nc-indicators/deploy # cd ..
/tmp/nc-indicators # mv deploy nc-indicators
/tmp/nc-indicators # tar cfz nc-indicators.tar.gz nc-indicators
/tmp/nc-indicators # rm -rf nc-indicators
/tmp/nc-indicators # ls -l nc-indicators.tar.gz
-rw-r--r--    1 root     root       8288196 Jun 15 11:56 nc-indicators.tar.gz
/tmp/nc-indicators # mv nc-indicators.tar.gz /tmp/x
```

Inside the `deploy` directory, we have created a `lib` subdir and then
copied there all the needed `.so` files based on the output of `ldd`.
After that, we had to use
[`patchelf`](https://nixos.org/patchelf.html) to convince the kernel
and the dynamic loader to use the libraries from the `lib` directory
and not from `/lib` and `/usr/lib`.

As a last step we have just packaged up everything to a final `tar.gz` file.

## Testing on a Debian

```
errge@brooks:/tmp/x $ tar xfz nc-indicators.tar.gz
errge@brooks:/tmp/x $ cd nc-indicators/
errge@brooks:/tmp/x/nc-indicators $ ./nc-indicators
```

It works.

There is a small issue though, if we try from a different directory:

```
errge@brooks:~ $ /tmp/x/nc-indicators/nc-indicators
bash: /tmp/x/nc-indicators/nc-indicators: No such file or directory
```

This "No such file or directory" error refers the dynamic loader,
called `lib/ld-musl-x86_64.so.1`.  Unfortunately, the kernel is
looking for this file relative to the current working directory, not
relative to the executable.

To fix this, we have to create a wrapper script:

```
errge@brooks:/tmp/x/nc-indicators $ mv nc-indicators nc-indicators.real
errge@brooks:/tmp/x/nc-indicators $ cat >nc-indicators <'EOF'
#!/bin/sh
STANDALONE_DIR="$(dirname $(readlink -f $0))"
exec "$STANDALONE_DIR/lib/ld-musl-x86_64.so.1" "$STANDALONE_DIR/nc-indicators.real" "$@"
EOF
errge@brooks:/tmp/x/nc-indicators $ chmod a+x nc-indicators
```

Of course, if you can ensure that in your environment the binary is
always started from its directory, you don't need the wrapper script.

## Thanks

The amazing patchelf tool is developed and maintained as part of the
promising NixOS project.  Big thanks!
