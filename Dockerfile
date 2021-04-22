FROM gcc:9 AS gcc
# FROM debian:latest

ARG CMAQ_USER="cmaq"
ARG CMAQ_UID="1000"
ARG CMAQ_GID="100"

ENV BUILD_HOME /cmaq
ENV CMAQ_HOME /usr/local/src/CMAQ_REPO
ENV LD_LIBRARY_PATH /usr/local/lib
ENV compiler gcc
ENV MPIVERSION openmpi

RUN apt-get update && apt-get install -y \
    bc \
    curl \
    findutils \
    git \
    time \
    tmux \
    wget \
  && rm -rf /var/lib/apt/lists/*

WORKDIR $BUILD_HOME
COPY build-gcc.sh .
COPY test-gcc.sh .
RUN $BUILD_HOME/build-gcc.sh

# build ioapi
COPY applydiff /usr/local/bin/applydiff
COPY build-ioapi.sh .
RUN $BUILD_HOME/build-ioapi.sh

COPY build-cmaq.sh .
RUN $BUILD_HOME/build-cmaq.sh

RUN useradd -m -s /bin/bash -N -u $CMAQ_UID $CMAQ_USER && \
    chown -R $CMAQ_USER:$CMAQ_GID $CMAQ_HOME/CCTM/scripts

ENV TTYD_BIN /usr/local/bin/ttyd
RUN wget https://github.com/tsl0922/ttyd/releases/download/1.6.3/ttyd.x86_64 -O $TTYD_BIN && chmod +x $TTYD_BIN

USER $CMAQ_USER
WORKDIR $CMAQ_HOME/CCTM/scripts

CMD ["/bin/bash", "-c", "$BUILD_HOME/test-gcc.sh"]

# CMD ["/usr/local/bin/ttyd","-p","7681","/bin/bash"]
