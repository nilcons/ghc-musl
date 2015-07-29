FROM alpine:latest

WORKDIR /tmp
COPY get-last-layer.sh build.mk fix-execvpe-signature-ghc-7.8.4.patch ./
RUN : "Layer 1: fully working basic GHC in /usr/local" && \
    apk --update add curl xz alpine-sdk perl gmp-dev file gmp openssh openssl zlib-dev strace vim less jq ncurses-dev bash autoconf && \
    : Install patchelf && \
    curl -L https://nixos.org/releases/patchelf/patchelf-0.8/patchelf-0.8.tar.bz2 | tar xj && \
    cd patchelf-0.8 && \
    ./configure && \
    make install && \
    : Overlay ghc cross compiler image && \
    cd /tmp && \
    sh get-last-layer.sh nilcons/ghc-musl-auto ghc-cross | tar xzO | tar xJ -C / && \
    : Compile the ghc binary distribution && \
    cd /tmp && \
    curl -L https://www.haskell.org/ghc/dist/7.8.4/ghc-7.8.4-src.tar.bz2 | tar xj && \
    cd ghc-7.8.4 && \
    cp -v /tmp/build.mk mk/build.mk && \
    patch -p1 </tmp/fix-execvpe-signature-ghc-7.8.4.patch && \
    PATH=/opt/ghc-cross/bin:$PATH ./configure && \
    : patch libffi bug && \
    sed -i 's,chmod,sed -i s/__gnu_linux__/1/ libffi/build/src/closures.c \&\& chmod,' libffi/ghc.mk && \
    make -j8 && \
    make binary-dist && \
    : Install the ghc binary distribution to minimize docker layer size && \
    cd /tmp && \
    tar xjf ghc-7.8.4/ghc-7.8.4-x86_64-unknown-linux.tar.bz2 --transform 's/^ghc-7.8.4/ghc-binary-dist/' && \
    cd ghc-binary-dist && \
    ./configure && \
    : musl ld requires --no-pie to work for some reason with ghc && \
    sed -i '/C\ compiler\ link/{ s/""/"--no-pie"/ }' settings && \
    make install && \
    : Clean up to keep the image small && \
    rm -rf /tmp/*

ENV PATH=/root/.cabal/bin:$PATH
RUN : "Layer 2: cabal-install, but only the binary, no executables" && \
    curl -L https://hackage.haskell.org/package/cabal-install-1.22.6.0/cabal-install-1.22.6.0.tar.gz | tar xz && \
    cd cabal-install-1.22.6.0 && \
    sed -i 's/export TMPDIR=.*/export TMPDIR=$(mktemp -t cabal-XXXXXX -d)/' bootstrap.sh && \
    EXTRA_CONFIGURE_OPTS=--disable-library-profiling ./bootstrap.sh && \
    : Clean up to keep the image small && \
    rm -rf /tmp/* /root/.ghc /root/.cabal/{lib,share}

WORKDIR /root/.cabal
RUN : "Layer 3: install stack" && \
    cabal update && \
    cabal install --global stack && \
    stack setup && \
    : Clean up to keep the image small && \
    rm -rf /root/.cabal

WORKDIR /tmp
RUN : "Layer 4: install packages" && \
    : the ncurses hackage package is a little bit broken && \
    ln -s /usr/include /usr/include/ncursesw && \
    apk add curl-dev openssl-dev zeromq-dev libx11-dev libxkbfile-dev libxfont-dev \
            libxcb-dev libxv-dev libxt-dev libxdmcp-dev libxp-dev libxshmfence-dev libxft-dev \
            libxxf86dga-dev libxtst-dev libxxf86misc-dev libxfixes-dev libxkbui-dev libxpm-dev \
            libxcomposite-dev libxaw-dev libxau-dev libxinerama-dev libxkbcommon-dev \
            libxmu-dev libxext-dev libxdamage-dev libxxf86vm-dev libxi-dev libxrandr-dev \
            libxres-dev libxcursor-dev libxrender-dev libxvmc-dev fuse-dev \
            mesa-dev glu-dev freeglut-dev gtk+2.0-dev && \
    stack install HUnit HsOpenSSL MissingH QuickCheck SafeSemaphore X11 acid-state \
                  alex async attoparsec basic-prelude bytedump c2hs classy-prelude-conduit \
                  clock colour conduit conduit-combinators conduit-extra cookie \
                  criterion crypto-api crypto-pubkey cryptohash curl data-accessor-template \
                  data-default data-memocombinators digest direct-sqlite distributed-process \
                  double-conversion elerea fgl filemanip foldl gtk gtk2hs-buildtools hamlet happy \
                  hashable haskeline haskell-src haskell-src-exts haskell-src-meta \
                  hflags hit hslogger hspec html http-client http-client-tls \
                  http-conduit http-types hybrid-vectors kan-extensions lens lens-datetime \
                  linear mime-mail modular-arithmetic monad-loops multimap ncurses \
                  netwire network-conduit network-transport-tcp parallel parsers \
                  path-pieces persistent persistent-template pipes pipes-bytestring \
                  pipes-safe pipes-zlib pretty-show primitive random-fu regex-base \
                  regex-compat regex-posix regex-tdfa regex-tdfa-rc regex-tdfa-text \
                  safecopy shakespeare shakespeare-css snap snap-blaze snap-core \
                  sodium split sqlite-simple statistics statvfs syb tasty tasty-hunit \
                  temporary test-framework test-framework-hunit test-framework-quickcheck2 \
                  test-framework-th thyme tls trifecta tz tzdata unbounded-delays \
                  unix-bytestring unix-time unordered-containers utf8-string utility-ht \
                  uuid vector vector-algorithms vector-th-unbox x509 xml-conduit \
                  xtest yesod yesod-static zeromq4-haskell zip-archive zlib-conduit && \
    : template-default needs jailbreaking && \
    stack unpack template-default && \
    cd template-default-* && \
    sed -i 's/2.9/2.10/' template-default.cabal && \
    stack init && \
    stack install && \
    : deepseq-th jailbreaking && \
    cd /tmp && \
    stack unpack deepseq-th && \
    cd deepseq-th-* && \
    sed -i 's/base.*,/base,/' deepseq-th.cabal && \
    sed -i 's/2.9/2.10/' deepseq-th.cabal && \
    stack init && \
    stack install && \
    cd /tmp && \
    : "bindings-posix fixes: musl has no POSIX2_{CHAR_TERM,LOCALEDEF}" && \
    stack unpack bindings-posix && \
    cd bindings-posix-* && \
    sed -i 's/#num _POSIX2_CHAR_TERM//' src/Bindings/Posix/Unistd.hsc && \
    sed -i 's/#num _POSIX2_LOCALEDEF//' src/Bindings/Posix/Unistd.hsc && \
    stack init && \
    stack install && \
    cd /tmp && \
    : "hmatrix should use random in musl, not random_r, also openblas..." && \
    echo "@testing http://dl-4.alpinelinux.org/alpine/edge/testing" >>/etc/apk/repositories && \
    apk add --update openblas-dev@testing && \
    stack unpack hmatrix && \
    cd hmatrix-* && \
    sed -i 's/def __APPLE__/ 1/' src/C/vector-aux.c && \
    stack init && \
    stack install --flag hmatrix:openblas && \
    : Clean up to keep the image small && \
    rm -rf /tmp/*

# TODO: network-protocol-xmpp supports libgsasl only, not cyrus-sasl-dev,
#       either have to fix that or put a libgsasl-dev into Alpine

WORKDIR /
CMD /bin/sh
