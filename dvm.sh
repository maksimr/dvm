# Dart Version Manager
# Implemented as a bash function
# To use source this file from your bash profile
# Based on nvm source code

# Auto detect the DVM_DIR
if [ ! -d "$DVM_DIR" ]; then
    export DVM_DIR=$(cd $(dirname ${BASH_SOURCE[0]:-$0}); pwd)
fi

# Expand a revision by version
dvm_revision() {
    VERSION=${1##v} #VERSION
    local REVISION=''

    if [ -f "$DVM_DIR/.cache/.version" ]
    then
        REVISION=$(cat "$DVM_DIR/.cache/.version" | grep "$VERSION")
        REVISION=${REVISION##*r\0?}
        REVISION=${REVISION##*r}
    fi

    echo "$REVISION"
}

# Expand a version using the version cache
dvm_version() {
    local PATTERN=$1
    # The default version is the current one
    if [ ! "$PATTERN" ]; then
        PATTERN='current'
    fi

    VERSION=`dvm_ls $PATTERN | tail -n1`
    echo "$VERSION"

    if [ "$VERSION" = 'N/A' ]; then
        return
    fi
}

dvm_ls() {
    local PATTERN=$1
    VERSIONS=''

    if [ "$PATTERN" = 'current' ]; then
        echo `dart --version 2>/dev/null` |
        egrep -o '[0-9]\.[0-9](\.[0-9])?' |
        xargs -I{} echo v{}
        return
    fi

    if [ -f "$DVM_DIR/alias/$PATTERN" ]; then
        dvm_version `cat $DVM_DIR/alias/$PATTERN`
        return
    fi

    # If it looks like an explicit version, don't do anything funny
    if [[ "$PATTERN" == v?*.?*.?* ]]; then
        VERSIONS="$PATTERN"
    else
        VERSIONS=`(cd $DVM_DIR; \ls -d v${PATTERN}* 2>/dev/null) | sort -t. -u -V`
    fi

    if [ ! "$VERSIONS" ]; then
        echo "N/A"
        return
    fi

    echo "$VERSIONS"
    return
}

print_versions()
{
    local OUTPUT=''
    local PADDED_VERSION=''
    for VERSION in $1; do
        PADDED_VERSION=`printf '%10s' $VERSION`
        if [[ -d "$DVM_DIR/$VERSION" ]]; then
            PADDED_VERSION="\033[0;34m$PADDED_VERSION\033[0m"
        fi
        OUTPUT="$OUTPUT\n$PADDED_VERSION"
    done
    echo -e "$OUTPUT" | column
}

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
    local ACTION="$1"
    local SYSTEM=$(dvm_check system)

    #process arguments
    case "$ACTION" in
        "help" )
            echo
            echo "Dart Version Manager"
            echo
            echo "Usage:"
            echo "    dvm help                    Show this message"
            echo "    dvm install <version>       Download and install a <version>"
            echo "    dvm uninstall <version>     Uninstall a version"
            echo "    dvm use <version>           Modify PATH to use <version>"
            echo "    dvm run <version> [<args>]  Run <version> with <args> as arguments"
            echo "    dvm ls                      List installed versions"
            echo "    dvm ls <version>            List versions matching a given description"
            echo "    dvm ls-remote               List remote versions available for install"
            echo "    dvm deactivate              Undo effects of DVM on current shell"
            echo "    dvm alias [<pattern>]       Show all aliases beginning with <pattern>"
            echo "    dvm alias <name> <version>  Set an alias named <name> pointing to <version>"
            echo "    dvm unalias <name>          Deletes the alias named <name>"
            echo
            ;;
        "ls-remote")
            dvm_check 'curl'
            local DART_URI='http://commondatastorage.googleapis.com/dart-editor-archive-integration/'
            local DVM_CACHE_DIR="$DVM_DIR/.cache"

            #if cache directory doesn't exist create it
            if [ ! -d "$DVM_CACHE_DIR" ]
            then
                mkdir -p "$DVM_CACHE_DIR"
            fi

            curl -s $DART_URI |
            egrep -o '[0-9].[0-9](.[0-9])?.r[0-9]+' | # regexp {VERSION}.r{REVISION}
            sort -t. -u -V --output="$DVM_CACHE_DIR/.version"

            cat "$DVM_CACHE_DIR/.version" |
            egrep -o '[0-9]\.[0-9](\.[0-9])?' |
            xargs -I{} echo v{}
            ;;

        "install")
            dvm_check 'curl'
            VERSION=$(dvm_version $2) #VERSION
            local REVISION=$(dvm_revision $VERSION) #get revision by version
            local DART_URI='http://commondatastorage.googleapis.com/dart-editor-archive-integration'

            local tarball=''

            if [ -d "$DVM_DIR/${VERSION}" ]
            then
                echo "Dart ${VERSION} is already installed!"
                return
            fi

            local tarball="$DART_URI/$REVISION/dartsdk-${SYSTEM}.tar.gz"

            if [ "`curl -Is "${tarball}" | grep '200 OK'`" = '' ];
            then
                echo "Dart $VERSION doesn't exist on remote server! To see remote version use ls-remote option"
                return
            fi

            if (
                mkdir -p "$DVM_DIR/tmp" && \
                    cd "$DVM_DIR/tmp" && \
                    curl -C - --progress-bar $tarball -o "dart-$VERSION.tar.gz" && \
                    mkdir -p "$DVM_DIR/$VERSION" && \
                    tar -xzf "dart-$VERSION.tar.gz" -C "$DVM_DIR/$VERSION" --strip-components 1 && \
                    rm -f "dart-$VERSION.tar.gz" 2>/dev/null && \
                    cd "$DVM_DIR/$VERSION"
                )
            then
                echo "dvm: install $VERSION successfully!"
            else
                echo "dvm: install $VERSION failed!"
            fi
            ;;
        "uninstall" )
            VERSION=$(dvm_version $2) #VERSION
            if [ ! -d "$DVM_DIR/$VERSION" ]; then
                echo "$VERSION is not installed yet"
                return;
            fi

            rm -rf "$DVM_DIR/$VERSION" 2>/dev/null

            echo "Uninstalled dart $VERSION"
            ;;
        "ls" | "list" )
            print_versions "`dvm_ls $2`"
            if [ $# -eq 1 ]; then
                echo -ne "current: \t"; dvm_version current
                dvm alias
            fi
            return
            ;;
        "run" )
            # run given version of dart
            if [ $# -lt 2 ]; then
                dvm help
                return
            fi

            VERSION=$(dvm_version $2) #VERSION

            if [ ! -d $DVM_DIR/$VERSION ]; then
                echo "$VERSION version is not installed yet"
                return;
            fi
            echo "Running dart $VERSION"
            $DVM_DIR/$VERSION/bin/dart "${@:3}"
            ;;
        "use" )
            VERSION=$(dvm_version $2) #VERSION
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
        "deactivate" )
            if [[ $PATH == *$DVM_DIR/*/bin* ]]; then
                export PATH=${PATH%$DVM_DIR/*/bin*}${PATH#*$DVM_DIR/*/bin:}
                hash -r
                echo "$DVM_DIR/*/bin removed from \$PATH"
            else
                echo "Could not find $DVM_DIR/*/bin in \$PATH"
            fi
            ;;
        "alias" )
            local DEST

            mkdir -p $DVM_DIR/alias

            if [ $# -le 2 ]
            then
                (cd $DVM_DIR/alias && for ALIAS in `\ls $2* 2>/dev/null`; do
                DEST=`cat $ALIAS`
                VERSION=`dvm_version $DEST`
                if [ "$DEST" = "$VERSION" ]; then
                    echo "$ALIAS -> $DEST"
                else
                    echo "$ALIAS -> $DEST (-> $VERSION)"
                fi
            done)
            return
        fi

        if [ ! "$3" ]; then
            rm -f $DVM_DIR/alias/$2
            echo "$2 -> *poof*"
            return
        fi

        VERSION=`dvm_version $3`
        if [ $? -ne 0 ]; then
            echo "! WARNING: Version '$3' does not exist." >&2
        fi
        echo $3 > "$DVM_DIR/alias/$2"
        if [ ! "$3" = "$VERSION" ]; then
            echo "$2 -> $3 (-> $VERSION)"
        else
            echo "$2 -> $3"
        fi
        ;;
    "unalias" )
        mkdir -p $DVM_DIR/alias
        [ $# -ne 2 ] && dvm help && return
        [ ! -f $DVM_DIR/alias/$2 ] && echo "Alias $2 doesn't exist!" && return
        rm -f $DVM_DIR/alias/$2
        echo "Deleted alias $2"
        ;;
    * )
        dvm help
        ;;
esac
}

dvm ls default &>/dev/null && dvm use default >/dev/null || true
