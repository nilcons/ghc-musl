# GHC compiled with the musl libc

This project aims to provide a Docker image that:
- contains a GHC compiled with and targeting the musl libc (in
  contrast to the standard, but much more bloated glibc),
- contains a Cabal installation pre-configured with the LTS edition of Stackage,
- contains a lot of pre-installed Hackage packages.

This makes it possible to:
- compile fully statically quite complex Haskell binaries,
- if dynamic linking is still necessary or preferred, then easily
  distribute the required libc and additional .so files.

```
brooks:/tmp $ docker run -v /tmp/x:/tmp/x -it --rm nilcons/ghc-musl
/ # cd /tmp/x
/tmp/x # echo 'main = putStrLn "Hello World!"' >test.hs
/tmp/x # ghc --make -O2 -optl-static test
[1 of 1] Compiling Main             ( test.hs, test.o )
Linking test ...
/tmp/x # strip -s test
/tmp/x # file test
test: ELF 64-bit LSB executable, x86-64, statically linked, stripped
/tmp/x # exit
brooks:/tmp $ cd /tmp/x
brooks:/tmp/x $ ./test
Hello World!
brooks:/tmp/x $ ldd ./test
    not a dynamic executable
brooks:/tmp/x $ ls -l test
-rwxr-xr-x 1 root root 1158408 Jun 10 15:25 test
```

We see here, that the compilation happens inside a Docker container
created from the `nilcons/ghc-musl` image and then the resulting
binary is used on the host.  This binary is portable to any other
amd64 GNU/Linux distribution as it doesn't depend on anything.

```
brooks:/tmp/x $ strace -e file ./test
execve("./test", ["./test"], [/* 53 vars */]) = 0
Hello World!
+++ exited with 0 +++


brooks:/tmp/x $ strace -e file /bin/true
execve("/bin/true", ["/bin/true"], [/* 53 vars */]) = 0
access("/etc/ld.so.nohwcap", F_OK)      = -1 ENOENT (No such file or directory)
access("/etc/ld.so.preload", R_OK)      = -1 ENOENT (No such file or directory)
open("/etc/ld.so.cache", O_RDONLY|O_CLOEXEC) = 3
access("/etc/ld.so.nohwcap", F_OK)      = -1 ENOENT (No such file or directory)
open("/lib/x86_64-linux-gnu/libc.so.6", O_RDONLY|O_CLOEXEC) = 3
+++ exited with 0 +++
```

Please note the file access operations of (the standard, Debian
provided) `/bin/true` and our hello world example.  The `/bin/true`
executable does 5 file access operations just to return 0, while our
executable doesn't do any file operations to achieve its task.  For
more complex executables, shipping a glibc based standalone binary
will be even more challenging, as glibc will start to randomly open
and dlopen files for nss plugins, locale files, etc.

If you want to know more about the problems relating to static linking
with glibc, Google around or start here:
http://www.systutorials.com/5217/how-to-statically-link-c-and-c-programs-on-linux-with-gcc/

## Editions

`nilcons/ghc-musl:base`: a working GHC that targets the musl libc
is installed in `/usr/local`, this can be used to play around in
GHCi or to compile executables that doesn't depend on additional
libraries.

`nilcons/ghc-musl:cabal`: as an additional layer on top of base,
this also provides a `cabal-install` executable in
`/root/.cabal/bin/cabal`.  You can use this executable to easily
install packages from Hackage.

`nilcons/ghc-musl:stackage`: this edition contains a cabal
installation that is preconfigured with the Stackage LTS 2.12.
Stackage is a pre-tested collection of Hackage packages:
https://www.stackage.org/lts-2.12

`nilcons/ghc-musl:latest`: this edition installs a lot of Haskell
packages that are used by most Haskell projects.  The list of packages
are ad-hoc, please feel free to open a GitHub issue on this project to
include additional libraries that you need.  The list of packages that
we currently ship can be found in [`packages.txt`](packages.txt).

If you use the `docker run -it --rm nilcons/ghc-musl` command to
start a new container, you will get the `latest` edition, that
contains all the packages and most probably is what you want.  If you
want something more basic, please specify the edition name directly,
e.g. `docker run -it --rm nilcons/ghc-musl:base`.

You can find all this editions and labels on
[DockerHub](https://registry.hub.docker.com/u/nilcons/ghc-musl/tags/manage/).

## Use case: static compilation of PrefetchFS
[See README.PrefetchFS.md](README.PrefetchFS.md)

## Use case: distribution of nc-indicators
[See README.nc-indicators.md](README.nc-indicators.md)

## Use case: full fledged Hackage LTS Docker playground

If you don't have anything to productionalize, you can also use the
`nilcons/ghc-musl:latest` image just to play around with Haskell
without installing it on the host machine.

Just use the `docker -it --rm nilcons/ghc-musl` command to start a
shell where you can run `ghci` to get a Haskell REPL with hundreds
of libraries already shipped.

## Developer notes, internals:
Reproducing the docker images is a multi step process:

- https://github.com/nilcons/ghc-musl/tree/master/ghc-cross : this
  directory contains a Debian based Docker image that cross compiles a
  musl based GHC and the last layer contains a `tar.gz` of that,
  the output is `nilcons/ghc-musl-auto:ghc-cross` after a successful
  DockerHub build.

- https://github.com/nilcons/ghc-musl/tree/master/ghc-musl : this is
  the real stuff, it uses the GHC binary from the `ghc-cross` step
  and goes through the recompilation of the GHC, bootstrapping of
  Cabal and cabal-install and installation of all the shipped
  packages.  The output after a successful autobuild is
  `nilcons/ghc-musl-auto:ghc-musl` .

- After this use the [`scripts/retag.sh`](scripts/retag.sh) script
  to tag the editions and push to `nilcons/ghc-musl:*`, the script
  also updates the package listing in the documentation.

This last step is necessary, because our editions are just different
layers in the build process of the same Dockerfile.  The other option
would be to create a chain of Dockerfiles, but currently there is no
good dependency handling mechanism for this on DockerHub.  This will
hopefully change in the future and then we will get rid of the shell
script.

## Thanks to

The idea for this project is from a reddit post:
http://www.reddit.com/r/haskell/comments/37m7q7/ghc_musl_easier_static_linking/

The post provided the motivation for figuring out the details of
reproducing the result and then building and compiling the whole
infrastructure on top of it.

Of course, all this hacking would be impossible without the
invaluable http://www.musl-libc.org/

Also, using musl directly would have been much-much harder if the very
professionally built http://alpinelinux.org/ were not available for
us.

Finally, we would like to thank the organizers of
https://wiki.haskell.org/ZuriHac2015 as that provided the initial push
to start this project.

## Further work

We want to include more tools in the image, e.g. Hoogle and ghc-mod,
so you can use it as the backend for your editor and/or documentation
browser.

Also, it might be worth a try to write some wrappers around `cabal`,
`ghc`, `ghci` and other related executables that forward calls to a
daemonized docker container that communicates with the host via Docker
volumes.

Naturally (and maybe most urgently), we want to target versions of GHC
other than 7.8.4 and various Stackage editions.  If any of this is
important to you, please provide feedback to us on the Reddit thread
(TODO: reddit link).

## About us

Nilcons is a small consulting and training shop in Zürich, Switzerland.

For casual social networking, please join us on Twitter
[https://twitter.com/nilconshq](@NilconsHQ).

For feedback regarding this project, please use the Reddit thread
(TODO: link).

For commercial enquiries please use the cons@nilcons.com email address.
