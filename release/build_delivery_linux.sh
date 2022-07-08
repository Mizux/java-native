#!/usr/bin/env bash
set -eo pipefail

function help() {
  local -r NAME=$(basename "$0")
  local -r BOLD="\e[1m"
  local -r RESET="\e[0m"
  local -r help=$(cat << EOF
${BOLD}NAME${RESET}
\t$NAME - Build delivery using the ${BOLD}local host system${RESET}.
${BOLD}SYNOPSIS${RESET}
\t$NAME [-h|--help|help] [examples|dotnet|java|python|all|reset]
${BOLD}DESCRIPTION${RESET}
\tBuild project deliveries.
\tYou ${BOLD}MUST${RESET} define the following variables before running this script:
\t* PROJECT_TOKEN: secret use to decrypt keys to sign .Net and Java packages.

${BOLD}OPTIONS${RESET}
\t-h --help: display this help text
\tjava: build all Java packages (default)

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

# Java build
function build_java() {
  command -v swig
  command -v swig | xargs echo "swig: " | tee -a build.log
  # maven require JAVA_HOME
  if [[ -z "${JAVA_HOME}" ]]; then
    echo "JAVA_HOME: not found !" | tee -a build.log
    exit 1
  else
    echo "JAVA_HOME: ${JAVA_HOME}" | tee -a build.log
    command -v java | xargs echo "java: " | tee -a build.log
    command -v javac | xargs echo "javac: " | tee -a build.log
    command -v jar | xargs echo "jar: " | tee -a build.log
    command -v mvn | xargs echo "mvn: " | tee -a build.log
  fi
  # Maven central need gpg sign and we store the release key encoded using openssl
  local OPENSSL_PRG=openssl
  if [[ -x $(command -v openssl11) ]]; then
    OPENSSL_PRG=openssl11
  fi
  command -v $OPENSSL_PRG | xargs echo "openssl: " | tee -a build.log
  command -v gpg
  command -v gpg | xargs echo "gpg: " | tee -a build.log

  # Install Java GPG
  echo -n "Install Java GPG..." | tee -a build.log
  $OPENSSL_PRG aes-256-cbc -iter 42 -pass pass:"$PROJECT_TOKEN" \
  -in release/private-key.gpg.enc \
  -out private-key.gpg -d
  gpg --batch --import private-key.gpg
  # Don't need to trust the key
  #expect -c "spawn gpg --edit-key "corentinl@google.com" trust quit; send \"5\ry\r\"; expect eof"

  # Install the maven settings.xml having the GPG passphrase
  mkdir -p ~/.m2
  $OPENSSL_PRG aes-256-cbc -iter 42 -pass pass:"$PROJECT_TOKEN" \
  -in release/settings.xml.enc \
  -out ~/.m2/settings.xml -d
  echo "DONE" | tee -a build.log

  # Clean java
  echo -n "Clean Java..." | tee -a build.log
  cd "${ROOT_DIR}" || exit 2
  rm -rf "${ROOT_DIR}/temp_java"
  echo "DONE" | tee -a build.log

  echo -n "Build Java..." | tee -a build.log

  if [[ ! -v GPG_ARGS ]]; then
    GPG_EXTRA=""
  else
    GPG_EXTRA="-DGPG_ARGS=${GPG_ARGS}"
  fi

  # shellcheck disable=SC2086: cmake fail to parse empty string ""
  cmake -S. -Btemp_java -DBUILD_SAMPLES=OFF -DBUILD_EXAMPLES=OFF \
 -DBUILD_JAVA=ON -DSKIP_GPG=OFF ${GPG_EXTRA}
  cmake --build temp_java -j8 -v
  echo "DONE" | tee -a build.log
  #cmake --build temp_java --target test
  #echo "cmake test: DONE" | tee -a build.log

  # copy jar to export
  cp temp_java/java/javanative-linux-x86-64/target/*.jar* export/
  cp temp_java/java/javanative-java/target/*.jar* export/
}

# Cleaning everything
function reset() {
  echo "Cleaning everything..."
  make clean
  rm -rf temp_java
  rm -rf export/
  rm -f ./*.log
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

