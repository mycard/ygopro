FROM alpine as builder
WORKDIR /usr/src
RUN apk add g++ make binutils sqlite-dev libevent-dev
RUN wget https://github.com/premake/premake-core/releases/download/v5.0.0-alpha14/premake-5.0.0-alpha14-src.zip && \
    unzip premake-5.0.0-alpha14-src.zip && \
    mv premake-5.0.0-alpha14 premake && \
    cd /usr/src/premake/build/gmake.unix && \
    make && \
    mv /usr/src/premake/bin/release/premake5 /usr/bin/ && \
    rm -r /usr/src/premake*
RUN wget https://www.lua.org/ftp/lua-5.4.3.tar.gz && \
    tar xf lua-5.4.3.tar.gz && \
    mv lua-5.4.3 lua && \
    cd /usr/src/lua/ && \
    make && \
    make install 
ADD . ygopro
RUN cd /usr/src/ygopro && \
    mv /usr/src/lua . && \
    mv premake/lua/premake5.lua lua/ && \
    premake5 gmake --build-lua --alpine-support && \
    cd build && \
    make config=release -j$(nproc) && \
    strip /usr/src/ygopro/bin/release/ygopro && \
    cp /usr/src/ygopro/bin/release/ygopro /usr/src/ygopro/ 
WORKDIR /usr/src/ygopro
ENTRYPOINT [ "./ygopro" ] 

FROM alpine
WORKDIR /usr/src/ygopro
RUN apk add --no-cache sqlite-libs libevent libstdc++ libgcc
COPY --from=builder /usr/src/ygopro/bin/release/ygopro /usr/src/ygopro/cards.cdb /usr/src/ygopro/lflist.conf ./
COPY script script 
ENTRYPOINT [ "./ygopro" ]