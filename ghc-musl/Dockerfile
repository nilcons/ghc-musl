FROM alpine:latest
COPY get-last-layer.sh build.mk fix-execvpe-signature-ghc-7.8.4.patch /tmp/
RUN : "Layer 1: fully working basic GHC in /usr/local" && \
    mkdir /tmp/ghc && \
    cd /tmp/ghc && \
    apk add --update curl xz alpine-sdk perl gmp-dev file gmp openssh openssl zlib-dev strace vim less jq ncurses-dev bash autoconf && \
    cd /tmp && \
    wget https://nixos.org/releases/patchelf/patchelf-0.8/patchelf-0.8.tar.bz2 && \
    tar xfj patchelf-0.8.tar.bz2 && \
    cd patchelf-0.8 && \
    ./configure && make install && \
    cd .. && \
    rm -rf patchelf* && \
    sh /tmp/get-last-layer.sh nilcons/ghc-musl-auto ghc-cross >ghc-cross.tar.gz && \
    tar xvfz ghc-cross.tar.gz && \
    tar -xvJ -C / -f /tmp/ghc/ghc-7.8.4-x86_64-unknown-linux-musl.tar.xz && \
    wget https://www.haskell.org/ghc/dist/7.8.4/ghc-7.8.4-src.tar.bz2 && \
    tar xvfj ghc-7.8.4-src.tar.bz2 && \
    cd /tmp/ghc/ghc-7.8.4 && \
    cp -v /tmp/build.mk mk/build.mk && \
    patch -p1 </tmp/fix-execvpe-signature-ghc-7.8.4.patch && \
    PATH=/opt/ghc-cross/bin:$PATH ./configure && \
    : "libffi has a bug, which we patch here" && \
    sed -i 's,chmod,sed -i s/__gnu_linux__/1/ libffi/build/src/closures.c \&\& chmod,' libffi/ghc.mk && \
    make -j8 && \
    make binary-dist && \
    cd /tmp && \
    mv ghc/ghc-7.8.4/ghc-7.8.4-x86_64-unknown-linux.tar.bz2 . && \
    rm -rf ghc /opt/ghc-cross && \
    : && \
    : end of build, but we want to minimize docker layer sizes && \
    : so we extract ghc here and delete the tarball && \
    : && \
    tar xvfj ghc-7.8.4-x86_64-unknown-linux.tar.bz2 && \
    cd ghc-7.8.4 && \
    ./configure && \
    : musl ld requires --no-pie to work for some reason with ghc && \
    sed -i '/C\ compiler\ link/{ s/""/"--no-pie"/ }' settings && \
    make install && \
    cd /tmp && \
    rm -rf ghc-7.8.4 ghc-7.8.4-x86_64-unknown-linux.tar.bz2

ENV PATH=/root/.cabal/bin:$PATH
RUN : "Layer 2: cabal-install, but only the binary, no executables" && \
    cd /tmp && \
    wget https://hackage.haskell.org/package/cabal-install-1.22.4.0/cabal-install-1.22.4.0.tar.gz && \
    tar xvfz cabal-install-1.22.4.0.tar.gz && \
    cd cabal-install-1.22.4.0 && \
    EXTRA_CONFIGURE_OPTS=--disable-library-profiling ./bootstrap.sh && \
    cd / && \
    rm -rf /root/.ghc /tmp/cabal-install-1.22.4.0* /tmp/cabal- /root/.cabal/lib /root/.cabal/share

RUN : "Layer 3: cabal-install from stackage and stackage is set up" && \
    cd /root/.cabal && \
    cabal update && \
    curl -sS 'https://www.stackage.org/lts-2.12/cabal.config?global=true' >>config && \
    : Waiting for https://github.com/haskell/network/commit/6afe609308b90c1fd4b185978a15d44bc1dbd678 && \
    : to hit Stackage LTS, until that we have a workaround, but this should be "cabal install cabal-install" && \
    cabal install --global mtl network-uri parsec random stm text zlib && \
    cabal unpack network-2.6.2.0 && \
    cd network-2.6.2.0 && \
    sed -i '/defined(AF_CAN)/ s/AF_CAN/NO_CAN_OF_WORMS/' Network/Socket/Types.hsc && \
    cabal install --global && \
    cd .. && \
    rm -rf network-2.6.2.0 && \
    cabal install --global cabal-install && \
    cd / && \
    : We regenerate the config with the stackage cabal, so that && \
    : they are compatible. && \
    rm -rf /root/.cabal && \
    cabal update && \
    cp /root/.cabal/config /root/.cabal/config.before-stackage && \
    curl -sS 'https://www.stackage.org/lts-2.12/cabal.config?global=true' >>/root/.cabal/config

RUN : "Layer 4: install some packages" && \
    : the ncurses hackage package is a little bit broken && \
    ln -s /usr/include /usr/include/ncursesw && \
    apk add curl-dev openssl-dev zeromq-dev libx11-dev libxkbfile-dev libxfont-dev \
            libxcb-dev libxv-dev libxt-dev libxdmcp-dev libxp-dev libxshmfence-dev libxft-dev \
            libxxf86dga-dev libxtst-dev libxxf86misc-dev libxfixes-dev libxkbui-dev libxpm-dev \
            libxcomposite-dev libxaw-dev libxau-dev libxinerama-dev libxkbcommon-dev \
            libxmu-dev libxext-dev libxdamage-dev libxxf86vm-dev libxi-dev libxrandr-dev \
            libxres-dev libxcursor-dev libxrender-dev libxvmc-dev fuse-dev \
            mesa-dev glu-dev freeglut-dev gtk+2.0-dev && \
    cabal install --global alex happy && \
    cabal install --global c2hs && \
    cabal install --global gtk2hs-buildtools && \
    cabal install --global attoparsec fgl haskell-src haskell-src-exts haskell-src-meta hashable html HUnit \
                           parallel QuickCheck regex-base regex-compat regex-posix split syb \
                           unordered-containers vector primitive async bytedump unix-bytestring colour \
                           conduit criterion crypto-api cryptohash curl data-accessor-template \
                           data-default data-memocombinators digest elerea filemanip foldl Glob \
                           lens haskeline hflags hit hslogger HsOpenSSL hspec hybrid-vectors \
                           kan-extensions lens-datetime linear mime-mail MissingH modular-arithmetic \
                           monad-loops netwire network-conduit pipes pipes-bytestring pipes-safe \
                           pipes-zlib pretty-show random-fu regex-tdfa regex-tdfa-rc regex-tdfa-text \
                           SafeSemaphore snap snap-blaze statistics statvfs \
                           temporary test-framework test-framework-hunit test-framework-th \
                           test-framework-quickcheck2 thyme tls trifecta tz tzdata unix-time \
                           utf8-string utility-ht vector-algorithms vector-th-unbox zip-archive \
                           X11 xtest zeromq4-haskell Hfuse direct-sqlite sqlite-simple \
                           gtk chart-gtk ncurses basic-prelude classy-prelude-conduit conduit-combinators \
                           conduit-extra double-conversion hamlet http-client \
                           http-client-tls http-conduit http-types path-pieces \
                           persistent persistent-template shakespeare \
                           shakespeare-css uuid xml-conduit yesod yesod-static \
                           zlib-conduit acid-state clock distributed-process multimap \
                           network-transport-tcp tasty tasty-hunit safecopy \
                           sodium unbounded-delays && \
    : template-default needs jailbraking && \
    cd /tmp && \
    cabal unpack -d template-default template-default && \
    cd /tmp/template-default/* && \
    sed s/2.9/2.10/ -i template-default.cabal && \
    cabal install --global --only-dependencies && \
    cabal install --global && \
    cd /tmp && \
    rm -rf template-default && \
    : gloss needs some love and a big pile of jailbraking && \
    cd /tmp && \
    cabal unpack -d gloss-rendering gloss-rendering-1.9.2.1 && \
    cd /tmp/gloss-rendering/* && \
    sed -i 's/GLUT.*/GLUT,/' gloss-rendering.cabal && \
    sed -i 's/OpenGL.*/OpenGL,/' gloss-rendering.cabal && \
    cabal install --global --only-dependencies && \
    cabal install --global && \
    cd /tmp && \
    rm -rf gloss-rendering && \
    cabal unpack -d gloss gloss-1.9.2.1 && \
    cd /tmp/gloss/* && \
    sed -i 's/GLUT.*==.*/GLUT,/' gloss.cabal && \
    sed -i 's/OpenGL.*==.*/OpenGL,/' gloss.cabal && \
    cabal install --global --only-dependencies && \
    cabal install --global && \
    cd /tmp && \
    rm -rf gloss && \
    : deepseq-th jailbraking && \
    cd /tmp && \
    cabal unpack -d deepseq-th deepseq-th && \
    cd /tmp/deepseq-th/* && \
    sed -i 's/base.*,/base,/' deepseq-th.cabal && \
    sed -i 's/2.9/2.10/' deepseq-th.cabal && \
    cabal install --global --only-dependencies && \
    cabal install --global && \
    cd /tmp && \
    rm -rf deepseq-th && \
    : "bindings-posix fixes: musl has no POSIX2_{CHAR_TERM,LOCALEDEF}" && \
    cd /tmp && \
    cabal unpack -d bindings-posix bindings-posix && \
    cd /tmp/bindings-posix/* && \
    sed -i 's/#num _POSIX2_CHAR_TERM//' src/Bindings/Posix/Unistd.hsc && \
    sed -i 's/#num _POSIX2_LOCALEDEF//' src/Bindings/Posix/Unistd.hsc && \
    cabal install --global --only-dependencies && \
    cabal install --global && \
    cd /tmp && \
    rm -rf bindings_posix && \
    : "hmatrix should use random in musl, not random_r, also openblas..." && \
    echo "@testing http://dl-4.alpinelinux.org/alpine/edge/testing" >>/etc/apk/repositories && \
    apk add --update openblas-dev@testing && \
    cd /tmp && \
    cabal unpack -d hmatrix hmatrix && \
    cd /tmp/hmatrix/* && \
    sed -i 's/def __APPLE__/ 1/' src/C/vector-aux.c && \
    cabal install --global --only-dependencies && \
    cabal install --global -f openblas && \
    cd /tmp && \
    rm -rf hmatrix

# TODO: network-protocol-xmpp supports libgsasl only, not cyrus-sasl-dev,
#       either have to fix that or put a libgsasl-dev into Alpine

CMD /bin/sh
