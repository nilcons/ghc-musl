FROM alpine:latest
RUN apk add --update curl xz alpine-sdk perl gmp-dev file gmp openssh openssl zlib-dev strace vim less
WORKDIR /tmp
RUN curl -o ghc.tar.xz https://s3.eu-central-1.amazonaws.com/ghc-musl.nilcons.com/ghc-7.8.4-x86_64-unknown-linux-musl.tar.xz
RUN xz -c -d /tmp/ghc.tar.xz | tar xf -
WORKDIR /tmp/ghc-7.8.4
RUN ./configure && make install

WORKDIR /usr/local/bin
RUN mv ghc-7.8.4 ghc-7.8.4.orig
RUN echo -e '#!/bin/sh\nexec ghc-7.8.4.orig "$@" -optl--no-pie' >ghc-7.8.4
RUN chmod 0755 ghc-7.8.4

WORKDIR /tmp
RUN curl -o cabal-install.tar.gz http://hackage.haskell.org/package/cabal-install-1.22.4.0/cabal-install-1.22.4.0.tar.gz
RUN tar xvfz cabal-install.tar.gz
WORKDIR /tmp/cabal-install-1.22.4.0
RUN EXTRA_CONFIGURE_OPTS=--disable-library-profiling\ --enable-shared SCOPE_OF_INSTALLATION=--global ./bootstrap.sh

WORKDIR /root
ENV PATH=/root/.cabal/bin:$PATH
CMD /bin/sh

RUN cabal update

#RUN /opt/bin/ghc --make -O2 --make -static -optc-static -optl-static /tmp/static.hs -optl-pthread -o /tmp/test
