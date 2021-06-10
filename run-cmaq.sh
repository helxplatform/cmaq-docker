#!/bin/bash

IMAGE=helxplatform/cmaq:latest
# Sometimes docker's cache of images doesn't pull the real 'latest' image.
# IMAGE=helxplatform/cmaq:202104212347
BENCHMARK_DATA="$HOME/CMAQv5.3.2_Benchmark_2Day_Input"
APPL=2016_12SE1
NPCOL=4
NPROW=4
CMAQ_SCRIPTS_DIR="/usr/local/src/CMAQ_REPO/CCTM/scripts"
CMD="bash -c $( cd $CMAQ_SCRIPTS_DIR && ./run_cctm.csh )"
PORT=""
CREDS=""
DOCKER_ARGS=""
ENTRYPOINT_SCRIPT=run_cctm.csh
EXTRA_DOCKER_OPTIONS=""

function print_help() {
  echo "\
usage: $0
  -a|--appl            specify data name (default=$APPL)
  -c|--npcol           specify npcol value (default=$NPCOL)
  -d|--data            specify data directory (default=$BENCHMARK_DATA)
  -e|--entrypoint      specify a script to mount in the container and run (default=run_cctm.csh)
  -h|--help            Print this help message.
  -i|--image           specify registry/repo:tag image (default = $IMAGE, ex. cmaq:latest)
  -o|--docker-options  specify any extra docker command options
  -r|--nprow           specify nprow value (default=$NPROW)
  -s|--shell           start a bash shell instead of running \"$CMD\"
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
      -e|--entrypoint)
        ENTRYPOINT_SCRIPT="$2"
        shift # past argument
        ;;
      -h|--help)
        print_help
        exit 0
        ;;
      -i|--image)
        IMAGE="$2"
        shift
        ;;
      -o|--docker-options)
        EXTRA_DOCKER_OPTIONS="$2"
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
      *)
        # unknown option
        print_help
        exit 1
        ;;
  esac
  shift # past argument or value
done

# Get directory containing this script.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TIMESTAMP=`date "+%Y%m%d%H%M"`
SCRIPT_LOG="$SCRIPT_DIR/log-$TIMESTAMP.txt"

docker run $DOCKER_ARGS $PORT \
    -v "$BENCHMARK_DATA:/usr/local/src/CMAQ_REPO/data" \
    -v "$SCRIPT_DIR/$ENTRYPOINT_SCRIPT:$CMAQ_SCRIPTS_DIR/run_cctm.csh" \
    -e APPL=$APPL \
    -e NPCOL=$NPCOL \
    -e NPROW=$NPROW \
    $EXTRA_DOCKER_OPTIONS \
    $IMAGE $CMD
