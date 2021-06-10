FROM jupyter/datascience-notebook

ENV BUILD_HOME /cmaq
ENV CMAQ_HOME /usr/local/src/CMAQ_REPO
ENV LD_LIBRARY_PATH /usr/local/lib
ENV compiler gcc
ENV MPIVERSION openmpi

user root

RUN apt-get update && apt-get install -y bc curl findutils gcc-9 git \
      libcurl4-openssl-dev m4 ssh tcsh time tmux vim wget zlib1g-dev \
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
RUN $BUILD_HOME/build-cmaq.sh && \
    fix-permissions "/home/${NB_USER}" && \
    rmdir $CMAQ_HOME/data && \
    ln -s /home/shared/cmaq/data $CMAQ_HOME/data && \
    ln -s /home/shared/cmaq/run_cctm.csh $CMAQ_HOME/CCTM/scripts/run_cctm.csh && \
    fix-permissions $CMAQ_HOME

# Should only need to set permissions for the scripts directory and not for all
# of $CMAQ_HOME.  Leaving it for now while we test.
#     fix-permissions $CMAQ_HOME/CCTM/scripts

USER $NB_UID
# WORKDIR $CMAQ_HOME/CCTM/scripts
WORKDIR "${HOME}"

# CMD ["/bin/bash", "-c", "$BUILD_HOME/test-gcc.sh"]
