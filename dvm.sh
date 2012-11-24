# Dart Version Manager
# Implemented as a bash function
# To use source this file from your bash profile
# Based on nvm source code

# Auto detect the DVM_DIR
if [ ! -d "$DVM_DIR" ]; then
    export DVM_DIR=$(cd $(dirname ${BASH_SOURCE[0]:-$0}); pwd)
fi

# check dependencies
dvm_check() {
    case "$1" in
        "curl")
            if [ ! `which curl` ]; then
                echo 'DVM Needs curl to proceed.' >&2;
                exit
            fi
            ;;
        "system")
            local uname="$(uname -a)"
            local os=''
            local arch="$(uname -m)"

            case "$uname" in
                Linux\ *)
                    os=linux ;;
                Darwin\ *)
                    os=darwin ;;
                SunOS\ *)
                    os=sunos ;;
            esac

            case "$uname" in
                *x86_64*)
                    arch=64 ;;
                *i*86*)
                    arch=32 ;;
            esac

            echo "${os}-${arch}"
            ;;
    esac
}

# general function
dvm() {
    local cmd="$1"
    local sdk_path="https://gsdview.appspot.com/dart-editor-archive-integration"
    local system=$(dvm_check system)

    #process arguments
    case "$cmd" in
        "help" )
            echo
            echo "Dart Version Manager"
            echo
            echo "Usage:"
            echo "    dvm help                    Show this message"
            echo "    dvm install <version>       Download and install a <version>"
            echo "    dvm uninstall <version>     Uninstall a version"
            echo "    dvm run <version> [<args>]  Run <version> with <args> as arguments"
            echo "    nvm ls                      List installed versions"
            echo "    nvm ls-remote               List remote versions available for install"
            echo "    dvm use <version>           Modify PATH to use <version>"
            echo
            ;;
        "ls-remote")
            # only revisions start 10000 have dartsdk
            # 13965 revision only for windows
            dvm_check 'curl'

            curl -s "${sdk_path}/" |
            egrep -o '[0-9]{5,}' |
            sed '/13965/d' |
            sort -t. -u -V --output="$DVM_DIR/.revisions"

            cat "$DVM_DIR/.revisions"
            ;;

        "install")
            dvm_check 'curl'
            VERSION="$2"
            local tarball=''
            local src_dir="$DVM_DIR/src"

            if [ -d "$DVM_DIR/r${VERSION}" ]
            then
                echo "Dart(${VERSION}) is already installed!"
                return
            fi

            local tarball="http://commondatastorage.googleapis.com/dart-editor-archive-integration/${VERSION}/dartsdk-${system}.tar.gz"

            if [ "`curl -Is "${tarball}" | grep '200 OK'`" = '' ];
            then
                echo "Dart(${VERSION}) doesn't exist on remote server!  You can use option remote_version"
                return
            fi

            if (
                mkdir -p "$src_dir" && \
                    cd "$src_dir" && \
                    curl -C - --progress-bar $tarball -o "dart-$VERSION.tar.gz" && \
                    mkdir -p "$DVM_DIR/r$VERSION" && \
                    tar -xzf "dart-$VERSION.tar.gz" -C "$DVM_DIR/r${VERSION}" --strip-components 1 && \
                    rm -f "dart-$VERSION.tar.gz" 2>/dev/null && \
                    cd "$DVM_DIR/r$VERSION"
                )
            then
                echo "dvm: install dart-$VERSION successfully!"
            else
                echo "dvm: install $VERSION failed!"
            fi
            ;;
        "uninstall" )
            VERSION="$2"
            if [ ! -d "$DVM_DIR/r$VERSION" ]; then
                echo "$VERSION version is not installed yet"
                return;
            fi

            rm -rf "$DVM_DIR/r$VERSION" 2>/dev/null

            echo "Uninstalled dart $VERSION"
            ;;
        "ls" | "list" )
            local d
            for d in $DVM_DIR/r*
            do
                if [ -d "$d" ]
                then
                    echo "$(basename ${d##*r})"
                fi
            done
            ;;
        "run" )
            # run given version of dart
            if [ $# -lt 2 ]; then
                dvm help
                return
            fi

            VERSION="$2"

            if [ ! -d $DVM_DIR/r$VERSION ]; then
                echo "$VERSION version is not installed yet"
                return;
            fi
            echo "Running dart $VERSION"
            $DVM_DIR/r$VERSION/bin/dart "${@:3}"
            ;;
        "use" )
            VERSION="$2"
            if [ ! -d $DVM_DIR/r$VERSION ]; then
                echo "$VERSION version is not installed yet"
                return;
            fi

            if [[ $PATH == *$DVM_DIR/*/bin* ]]; then
                PATH=${PATH%$DVM_DIR/*/bin*}$DVM_DIR/r$VERSION/bin${PATH#*$DVM_DIR/*/bin}
            else
                PATH="$DVM_DIR/r$VERSION/bin:$PATH"
            fi

            export PATH

            hash -r
            export DVM_BIN="$DVM_DIR/r$VERSION/bin"
            echo "Now using dart $VERSION"
            ;;
        * )
            dvm help
            ;;
    esac
}
