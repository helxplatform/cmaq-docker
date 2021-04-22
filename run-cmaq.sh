#!/bin/bash

IMAGE=helxplatform/cmaq:latest
# Sometimes docker's cache of images doesn't pull the real 'latest' image.
# IMAGE=helxplatform/cmaq:202104212347
BENCHMARK_DATA="$HOME/CMAQv5.3.2_Benchmark_2Day_Input"
APPL=2016_12SE1
NPCOL=4
NPROW=4
CMD="bash -c ./run_cctm_singularity.csh"
PORT=""
CREDS=""
RUN_TTYD=false
LOCAL_TTYD_PORT=7681
DOCKER_ARGS=""

function print_help() {
  echo "\
usage: $0
  -a|--appl            specify data name (default=$APPL)
  -c|--npcol           specify npcol value (default=$NPCOL)
  -d|--data            specify data directory (default=$BENCHMARK_DATA)
  -h|--help            Print this help message.
  -i|--local-image     use localhost registry for image
  -l|--local-ttyd-port specify TTYD port to use on localhost
  -r|--nprow           specify nprow value (default=$NPROW)
  -s|--shell           start a bash shell instead of running \"$CMD\"
  -t|--ttyd            start ttyd and launch a bash shell instead of running \"$CMD\"
"
}

while [[ $# > 0 ]]
  do
  key="$1"
  case $key in
      -a|--appl)
        APPL="$2"
        shift # past argument
        ;;
      -c|--npcol)
        NPCOL="$2"
        shift # past argument
        ;;
      -d|--data)
        BENCHMARK_DATA="$2"
        shift # past argument
        ;;
      -h|--help)
        print_help
        exit 0
        ;;
      -i|--local-image)
        IMAGE=cmaq:latest
        ;;
      -l|--local-ttyd-port)
        LOCAL_TTYD_PORT="$2"
        shift # past argument
        ;;
      -r|--nprow)
        NPROW="$2"
        shift # past argument
        ;;
      -s|--shell)
        CMD="/bin/bash"
        DOCKER_ARGS="--rm -it"
        ;;
      -t|--ttyd)
        RUN_TTYD=true
        ;;
      *)
        # unknown option
        print_help
        exit 1
        ;;
  esac
  shift # past argument or value
done

if $RUN_TTYD
then
  TTYD_PORT=7681
  PORT="-p $LOCAL_TTYD_PORT:$TTYD_PORT"
  TTYD_USER=cmaq
  TTYD_USER_PASSWORD=`openssl rand -hex 12`
  CREDS="-c $TTYD_USER:$TTYD_USER_PASSWORD"
  CMD="/usr/local/bin/ttyd $CREDS -p $TTYD_PORT /bin/bash"
  echo "ttyd user: $TTYD_USER"
  echo "ttyd user password: $TTYD_USER_PASSWORD"
  echo "connect to http://localhost:$LOCAL_TTYD_PORT"
fi

docker run $DOCKER_ARGS $PORT \
    -v "$BENCHMARK_DATA:/usr/local/src/CMAQ_REPO/data" \
    -e APPL=$APPL \
    -e NPCOL=$NPCOL \
    -e NPROW=$NPROW \
    $IMAGE $CMD
