FROM debian:8.0

RUN apt-get update
RUN apt-get install -y musl-tools build-essential wget curl ghc libncurses-dev less vim-tiny autoconf
# file

WORKDIR /tmp
RUN wget https://www.haskell.org/ghc/dist/7.8.4/ghc-7.8.4-src.tar.bz2
RUN tar xvfj ghc-7.8.4-src.tar.bz2
WORKDIR /tmp/ghc-7.8.4

COPY build.mk /tmp/ghc-7.8.4/mk/build.mk
RUN ./configure --target=x86_64-pc-linux-musl --with-gcc=musl-gcc --with-ld=ld --with-nm=nm --with-ar=ar  --with-ranlib=ranlib --prefix=/opt/ghc-cross

# stole this from https://github.com/redneb/ghc-alt-libc, thanks!
COPY fix-execvpe-signature-ghc-7.8.4.patch /tmp/fix-execvpe.patch
RUN patch -p1 </tmp/fix-execvpe.patch

# compile without ncurses or terminfo
RUN sed -i s/terminfo// ghc.mk
RUN sed -i s/terminfo// utils/ghc-pkg/ghc-pkg.cabal
RUN sed -i s/unix,/unix/ utils/ghc-pkg/ghc-pkg.cabal
RUN sed -i '1{p; s/.*/#define BOOTSTRAPPING/}' utils/ghc-pkg/Main.hs    

# update config.sub in libffi, so it supports x86_64-pc-linux
RUN sed -i 's,chmod,cp /usr/share/misc/config.sub libffi/build/config.sub \&\& chmod,' libffi/ghc.mk

# then just build it!
RUN make -j8

RUN make install
WORKDIR /opt/ghc-cross

# linked with glibc, not musl, build system bug, but we don't need it
RUN rm bin/x86_64-pc-linux-musl-hp2ps

# linked with glibc, not musl, build system bug, let's build an alternative one
RUN rm lib/x86_64-pc-linux-musl-ghc-7.8.4/unlit
RUN ( cd /tmp/ghc-7.8.4/utils/unlit ; musl-gcc unlit.c ) ; cp /tmp/ghc-7.8.4/utils/unlit/a.out lib/x86_64-pc-linux-musl-ghc-7.8.4/unlit

# we want to use normal gcc, not musl-gcc once we move this ghc-cross into a musl based distro
RUN sed -i 's/musl-gcc/gcc/' lib/x86_64-pc-linux-musl-ghc-7.8.4/settings

# musl ld requires --no-pie to work for some reason with ghc
RUN sed -i '/C\ compiler\ link/{ s/""/"--no-pie"/ }' lib/x86_64-pc-linux-musl-ghc-7.8.4/settings

# Remove the cross compiler prefix from binaries
RUN (cd bin ; for i in x86_64-pc-linux-musl-* ; do ln -s $i ${i#x86_64-pc-linux-musl-} ; done )

WORKDIR /
RUN tar cvfJ ghc-7.8.4-x86_64-unknown-linux-musl.tar.xz /opt/ghc-cross
