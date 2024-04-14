#!/bin/bash

set -e

LOG() {
    if [ $# -eq 0 ]; then
        printf "Usage: LOG [INFO|WARNING|ERROR] [Message1] [Message2]\n"
        printf "INFO show green, WARNING show yellow, and ERROR show red text, respectively\n"
        printf "if not given color will directly print the Message\n"
        return
    fi
    case "${1}" in
    INFO)
        shift
        echo -e "\033[32m$*\033[0m" | tr -s ' '
        ;;
    WARNING)
        shift
        echo -e "\033[33m$*\033[0m" | tr -s ' '
        ;;
    ERROR)
        shift
        echo -e "\033[31m$*\033[0m" | tr -s ' '
        exit 1
        ;;
    FATAL)
        shift
        echo -e "\033[31m$*\033[0m" | tr -s ' '
        exit 1
        ;;
    *)
        echo -e "$@"
        shift
        ;;
    esac
}

# the name of parameters response to its usage.
declare -A ARGS_DOCKER=()
ARGS_DOCKER["--force"]=0
ARGS_DOCKER["--build"]=0
ARGS_DOCKER["--enter"]=0
ARGS_DOCKER["--dry-run"]=0
ARGS_DOCKER["--start"]=1
ARGS_DOCKER["--help"]=0
ARGS_DOCKER["--verbose"]=0
ARGS_DOCKER["--initial"]=0
ARGS_DOCKER["--remove"]=0
ARGS_DOCKER["--remove-all"]=0
ARGS_DOCKER["--docker-build-args"]=""

PrintArguments() {
    LOG "The arguments key-value:"
    for key in "${!ARGS_DOCKER[@]}"; do
        LOG "$key" " "="${ARGS_DOCKER[$key]}"
    done
}

Usage() {
    LOG "Usage: ./docker.sh [-s|--start] [-f|--force] [-b|--build] [-e|--enter] [-h|--help]" ", " \
        "run \"./docker.sh\" without any arguments or \"./docker.sh --enter\" will satisfy most situation"
    LOG "Optional arguments:"
    LOG "\t" "-f|--force: ${ARGS_DOCKER["--force"]}, force remove exist container before do anything"
    LOG "\t" "-b|--build: ${ARGS_DOCKER["--build"]}, build the docker image"
    LOG "\t" "-e|--enter: ${ARGS_DOCKER["--enter"]}, enter the exist container by default name"
    LOG "\t" "-dr|--dry-run: ${ARGS_DOCKER["--dry-run"]}, just print the commands will be executed."
    LOG "\t" "-dba|--docker-build-args: ${ARGS_DOCKER["--docker-build-args"]}, number of docker build arguments, " \
        "just read one single string, eg: -dba \"-f Dockerfile.dev -t tag_something\""
    LOG "\t" "-h|--help: ${ARGS_DOCKER["--help"]}, enter the exist container by default name"
    LOG "\t" "-ra|--remove-all: ${ARGS_DOCKER["--remove-all"]}, remove image and container"
    LOG "\t" "-r|--remove: ${ARGS_DOCKER["--remove"]}, remove builded container"
    LOG "\t" "-i|--initial: ${ARGS_DOCKER["--initial"]}, initial container"
    LOG WARNING "\t" "-s|--start: ${ARGS_DOCKER["--start"]}, " \
        "default is true, if docker image is not exist it will build it first," \
        "if no contaniner running it will use docker run to initial the container then enter the container"
}
# LOG ERROR $0
PROJECT_DIR=$(realpath "$(dirname "$(dirname "$(realpath "$0")")")")
SOURCE_DIR=$PROJECT_DIR/src                       # SOURCE_DIR 必须在PROJECT_DIR/下的第一级目录
IMAGE_NAME=$(basename "$(dirname "$SOURCE_DIR")") # 镜像名称定义为PROJECT_DIR的名称
VERSION=v1.0
DOCKER_USER="jdl/${USER}"
FINAL_IMAGE_NAME=${DOCKER_USER}:${IMAGE_NAME}_${VERSION}
FINAL_CONTAINER_NAME=${IMAGE_NAME}_${VERSION}
if [ "${ARGS_DOCKER["--verbose"]}" -ne 0 ]; then
    LOG INFO "PROJECT_DIR: " "$PROJECT_DIR"
    LOG INFO "SOURCE_DIR: " "$SOURCE_DIR"
    LOG INFO "FINAL_IMAGE_NAME: " "$FINAL_IMAGE_NAME"
    LOG INFO "FINAL_CONTAINER_NAME: " "$FINAL_CONTAINER_NAME"
    LOG INFO "FINAL_IMAGE_NAME: " "$FINAL_CONTAINER_NAME"
fi
ExecOrDryRun() {
    LOG INFO "Exec command: $1"
    if [ "${ARGS_DOCKER["--dry-run"]}" -ne 0 ]; then
        return
    fi
    bash -c "$1"
}

BuildDockerImage() {
    EXTRA_BUILD_ARGS=""
    if [ "${ARGS_DOCKER["--docker-build-args"]}" != "" ]; then
        EXTRA_BUILD_ARGS="--build-arg ${ARGS_DOCKER["--docker-build-args"]}"
    fi
    ExecOrDryRun "docker build -f $PROJECT_DIR/docker/Dockerfile -t $FINAL_IMAGE_NAME $PROJECT_DIR/docker/ $EXTRA_BUILD_ARGS"
}

IntialDockerContainer() {
    INITIAL_COMMAND="docker run -it -d -v $PROJECT_DIR:/workspace/$(basename "$PROJECT_DIR") \
                                    --gpus all \
                                    -v /tmp/.X11-unix:/tmp/.X11-unix \
                                    -e DISPLAY=$DISPLAY \
                                    -w /workspace \
                                    --name ${FINAL_CONTAINER_NAME} \
                                    $FINAL_IMAGE_NAME"
    INITIAL_COMMAND=$(echo "$INITIAL_COMMAND" | tr -s ' ')
    # if -f|--force, force remove container before initial the container
    if [ "${ARGS_DOCKER["--force"]}" -ne 0 ]; then
        ExecOrDryRun "docker container rm -f $FINAL_CONTAINER_NAME"
    fi
    containerId="$(docker ps -a -q -f name=^"${FINAL_CONTAINER_NAME}"$)"
    if [ "$containerId" ]; then
        LOG ERROR "The container ${FINAL_CONTAINER_NAME} $containerId exist, \
            you can use -f or --force to force remove it before initial."
    fi
    ExecOrDryRun "$INITIAL_COMMAND"
}

EnterDockerContainer() {
    ExecOrDryRun "docker exec -it $FINAL_CONTAINER_NAME /entrypoint.sh"
}

# the positional arguments
ARGS_POSITIONAL=()
# start read the arguments
ARGS_COUNT=$#
while (($# > 0)); do
    case "${1}" in
    -f | --force)
        ARGS_DOCKER["--force"]=1
        shift
        ;;
    -b | --build)
        ARGS_DOCKER["--build"]=1
        shift
        ;;
    -e | --enter)
        ARGS_DOCKER["--enter"]=1
        shift
        ;;
    -dr | --dry-run)
        ARGS_DOCKER["--dry-run"]=1
        shift
        ;;
    -dba | --docker-build-args)
        numOfBuildArgs=1 # number of docker build arguments, just read one single string, eg, "-f Dockerfile.dev -t tag_something"
        if (($# < numOfBuildArgs + 1)); then
            shift $#
        else
            ARGS_DOCKER["--docker-build-args"]="${2}"
            shift $((numOfBuildArgs + 1))
        fi
        ;;
    -s | --start)
        # default is 1
        # ARGS_DOCKER["-s|--start"]=1
        shift
        ;;
    -v | --verbose)
        ARGS_DOCKER["--verbose"]=1
        shift
        ;;
    -i | --initial)
        ARGS_DOCKER["--initial"]=1
        shift
        ;;
    -r | --remove)
        ARGS_DOCKER["--remove"]=1
        shift
        ;;
    -ra | --remove-all)
        ARGS_DOCKER["--remove-all"]=1
        shift
        ;;
    -h | --help)
        ARGS_DOCKER["--help"]=1
        shift
        ;;
    *)
        ARGS_POSITIONAL+=("${1}")
        shift
        ;;
    esac
done

# output some information if --verbose is not 0
if [ "${ARGS_DOCKER["--verbose"]}" -ne 0 ]; then
    if [ ${#ARGS_POSITIONAL[@]} -gt 0 ]; then
        LOG WARNING "The arguments below are positional arguments which will be ignored: " "${ARGS_POSITIONAL[@]}"
    fi
    if [ ${#ARGS_DOCKER["--docker-build-args"]} -gt 0 ]; then
        LOG WARNING "The arguments below are transfer to docker build: " "${ARGS_DOCKER["--docker-build-args"]}"
    fi
    PrintArguments
fi

if [ "$ARGS_COUNT" -le 0 ]; then
    LOG INFO "use default options..."
    LOG INFO "Exec command: " "./docker.sh --start"
else
    # not the default docker build
    ARGS_DOCKER["--start"]=0
fi

if [ "${ARGS_DOCKER["--enter"]}" -ne 0 ]; then
    EnterDockerContainer
    exit 0
fi

if [ "${ARGS_DOCKER["--build"]}" -ne 0 ]; then
    BuildDockerImage
    exit 0
fi

if [ "${ARGS_DOCKER["--initial"]}" -ne 0 ]; then
    IntialDockerContainer
    exit 0
fi

if [ "${ARGS_DOCKER["--remove"]}" -ne 0 ]; then
    #清除此脚本所构建的容器和镜像
    ExecOrDryRun "docker container rm -f $FINAL_CONTAINER_NAME"
    exit 0
fi

if [ "${ARGS_DOCKER["--remove-all"]}" -ne 0 ]; then
    #清除此脚本所构建的容器和镜像
    ExecOrDryRun "docker image rm -f $FINAL_IMAGE_NAME"
    ExecOrDryRun "docker container rm -f $FINAL_CONTAINER_NAME"
    exit 0
fi

if [ "${ARGS_DOCKER["--help"]}" -ne 0 ]; then
    # 打印帮助信息
    Usage
    exit 0
fi

BuildDockerImage
IntialDockerContainer
EnterDockerContainer
