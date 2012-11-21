# Dart Version Manager
# Implemented as a bash function
# To use source this file from your bash profile
# Based on nvm source code

# Auto detect the DVM_DIR
if [ ! -d "$DVM_DIR" ]; then
  export DVM_DIR=$(cd $(dirname ${BASH_SOURCE[0]:-$0}) && pwd)
fi

dvm_version()
{
  PATTERN=$1
  # The default version is the current one
  if [ ! "$PATTERN" ]; then
    PATTERN='latest'
  fi

  VERSION=$PATTERN
  echo "$VERSION"
}

dvm() {
  local uname="$(uname -a)"
  local os=
  local arch="$(uname -m)"

  # Try to figure out the os and arch for binary fetching
  case "$uname" in
    Linux\ *) os=linux ;;
    Darwin\ *) os=darwin ;;
    SunOS\ *) os=sunos ;;
  esac
  case "$uname" in
    *x86_64*) arch=64 ;;
    *i*86*) arch=32 ;;
  esac

  case $1 in
    "help" )
      echo
      echo "Dart Version Manager"
      echo
      echo "Usage:"
      echo "    dvm help                    Show this message"
      echo "    dvm install <version>       Download and install a <version>"
      echo "    dvm uninstall <version>     Uninstall a version"
      echo "    dvm use <version>           Modify PATH to use <version>"
      echo
    ;;
    "install" )
      if [ ! `which curl` ]; then
        echo 'DVM Needs curl to proceed.' >&2;
      fi

      VERSION=`dvm_version $2`
      ADDITIONAL_PARAMETERS=''
      # Architectura 32-bit or 64-bit
      echo $VERSION
      if [ "`curl -Is "http://commondatastorage.googleapis.com/dart-editor-archive-integration/$VERSION/dartsdk-linux-$arch.tar.gz" | grep '200 OK'`" != '' ]; then
        tarball="http://commondatastorage.googleapis.com/dart-editor-archive-integration/$VERSION/dartsdk-linux-$arch.tar.gz"
      fi

      if (
        [ ! -z $tarball ] && \
          mkdir -p "$DVM_DIR/src" && \
          cd "$DVM_DIR/src" && \

          # remove archive and directory
          rm -rf "$DVM_DIR/$VERSION" 2>/dev/null && \

          curl -C - --progress-bar $tarball -o "dart-$VERSION.tar.gz" && \
          mkdir -p "$DVM_DIR/$VERSION" && \
          tar -xzf "dart-$VERSION.tar.gz" -C "$DVM_DIR/${VERSION}" --strip-components 1 && \
          rm -f "dart-$VERSION.tar.gz" 2>/dev/null && \
          cd "$DVM_DIR/$VERSION"
        )
      then
        echo "Dart installed"
      fi
    ;;
    "uninstall" )
      VERSION=`dvm_version $2`
      # notification
      if [ ! -d $DVM_DIR/$VERSION ]; then
        echo "$VERSION version is not installed yet"
        return;
      fi

      # Delete all files related to target version.
      (mkdir -p "$DVM_DIR/src" && \
          cd "$DVM_DIR/src" && \
          rm -f "dart-$VERSION.tar.gz" 2>/dev/null && \
          rm -rf "$DVM_DIR/$VERSION" 2>/dev/null)
      echo "Uninstalled dart $VERSION"
    ;;
    "use" )
      VERSION=`dvm_version $2`
      if [ ! -d $DVM_DIR/$VERSION ]; then
        echo "$VERSION version is not installed yet"
        return;
      fi

      if [[ $PATH == *$DVM_DIR/*/bin* ]]; then
        PATH=${PATH%$DVM_DIR/*/bin*}$DVM_DIR/$VERSION/bin${PATH#*$DVM_DIR/*/bin}
      else
        PATH="$DVM_DIR/$VERSION/bin:$PATH"
      fi

      export PATH

      hash -r
      export DVM_BIN="$DVM_DIR/$VERSION/bin"
      echo "Now using dart $VERSION"
    ;;
  esac
}

dvm use latest >/dev/null || true
