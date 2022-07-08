#!/usr/bin/env bash
set -eo pipefail

function help() {
  local -r NAME=$(basename "$0")
  local -r BOLD="\e[1m"
  local -r RESET="\e[0m"
  local -r help=$(cat << EOF
${BOLD}NAME${RESET}
\t$NAME - Build delivery using a ${BOLD}Manylinux 2.28 aarch64 docker image${RESET}.
${BOLD}SYNOPSIS${RESET}
\t$NAME [-h|--help|help] [java|reset]
${BOLD}DESCRIPTION${RESET}
\tBuild project deliveries.
\tYou ${BOLD}MUST${RESET} define the following variables before running this script:
\t* PROJECT_TOKEN: secret use to decrypt keys to sign .Net and Java packages.

${BOLD}OPTIONS${RESET}
\t-h --help: display this help text
\tjava: build all Java packages

${BOLD}EXAMPLES${RESET}
Using export to define the ${BOLD}PROJECT_TOKEN${RESET} env and only building the Java packages:
export PROJECT_TOKEN=SECRET
$0 java

note: the 'export ...' should be placed in your bashrc to avoid any leak
of the secret in your bash history
EOF
)
  echo -e "$help"
}

function assert_defined(){
  if [[ -z "${!1}" ]]; then
    >&2 echo "Variable '${1}' must be defined"
    exit 1
  fi
}

function build_delivery() {
  assert_defined PROJECT_TOKEN
  assert_defined PROJECT_DELIVERY
  assert_defined DOCKERFILE
  assert_defined PROJECT_IMG

  # Enable docker over QEMU support
  docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

  # Clean
  echo -n "Remove previous docker images..." | tee -a "${ROOT_DIR}/build.log"
  docker image rm -f "${PROJECT_IMG}":"${PROJECT_DELIVERY}" 2>/dev/null
  docker image rm -f "${PROJECT_IMG}":devel 2>/dev/null
  docker image rm -f "${PROJECT_IMG}":env 2>/dev/null
  echo "DONE" | tee -a "${ROOT_DIR}/build.log"

  cd "${ROOT_DIR}" || exit 2

  # Build env
  echo -n "Build ${PROJECT_IMG}:env..." | tee -a "${ROOT_DIR}/build.log"
  docker build --platform linux/arm64 \
    --tag "${PROJECT_IMG}":env \
    --target=env \
    -f release/"${DOCKERFILE}" .
  echo "DONE" | tee -a "${ROOT_DIR}/build.log"

  # Build devel
  echo -n "Build ${PROJECT_IMG}:devel..." | tee -a "${ROOT_DIR}/build.log"
  docker build --platform linux/arm64 \
    --tag "${PROJECT_IMG}":devel \
    --target=devel \
    -f release/"${DOCKERFILE}" .
  echo "DONE" | tee -a "${ROOT_DIR}/build.log"

  # Build delivery
  echo -n "Build ${PROJECT_IMG}:${PROJECT_DELIVERY}..." | tee -a "${ROOT_DIR}/build.log"
  docker build --platform linux/arm64 \
    --tag "${PROJECT_IMG}":"${PROJECT_DELIVERY}" \
    --build-arg PROJECT_TOKEN="${PROJECT_TOKEN}" \
    --build-arg PROJECT_DELIVERY="${PROJECT_DELIVERY}" \
    --target=delivery \
    -f release/"${DOCKERFILE}" .
  echo "DONE" | tee -a "${ROOT_DIR}/build.log"
}

# Java build
function build_java() {
  assert_defined PROJECT_IMG
  local -r PROJECT_DELIVERY=java
  build_delivery

  # copy .jar to export
  docker run --rm --init \
  -w /home/project \
  -v "${ROOT_DIR}/export":/export \
  -u "$(id -u "${USER}")":"$(id -g "${USER}")" \
  -t "${PROJECT_IMG}":"${PROJECT_DELIVERY}" "cp export/*.jar* /export/"
}

# Cleaning everything
function reset() {
  assert_defined PROJECT_IMG

  echo "Cleaning everything..."
  rm -rf export/
  docker image rm -f "${PROJECT_IMG}":java 2>/dev/null
  docker image rm -f "${PROJECT_IMG}":devel 2>/dev/null
  docker image rm -f "${PROJECT_IMG}":env 2>/dev/null
  rm -f "${ROOT_DIR}"/*.log

  echo "DONE"
}

# Main
function main() {
  case ${1} in
    -h | --help | help)
      help; exit ;;
  esac

  assert_defined PROJECT_TOKEN
  echo "PROJECT_TOKEN: FOUND" | tee -a build.log
  local -r ROOT_DIR="$(cd -P -- "$(dirname -- "$0")/.." && pwd -P)"
  echo "ROOT_DIR: '${ROOT_DIR}'" | tee -a build.log
  local -r RELEASE_DIR="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
  echo "RELEASE_DIR: '${RELEASE_DIR}'" | tee -a build.log

  local -r DOCKERFILE="arm64.Dockerfile"
  local -r PROJECT_IMG="project/manylinux_delivery_arm64"

  mkdir -p "${ROOT_DIR}"/export

  case ${1} in
    java)
      "build_$1"
      exit ;;
    reset)
      reset
      exit ;;
    *)
      >&2 echo "Target '${1}' unknown"
      exit 1
  esac
  exit 0
}

main "${1:-java}"

