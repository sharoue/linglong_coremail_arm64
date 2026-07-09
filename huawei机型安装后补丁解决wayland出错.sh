sudo bash -c '
SCRIPT=$(find /var/lib/linglong/layers -path "*/files/bin/cmclient" -type f -exec sh -c "head -n1 \"\$1\" | grep -q '^#!/bin/sh' && echo \"\$1\"" _ {} \; 2>/dev/null | head -1)
echo "Writing to: $SCRIPT"
cat > "$SCRIPT" << "EOF"
#!/bin/sh
set -e

if [ "$1" = "--kill" ]; then
    if [ -n "$(ps -A | grep -w cmclient)" ]; then
        killall -10 cmclient && sleep 5 || true
        if [ -n "$(ps -A | grep -w cmclient)" ]; then
            killall -3 cmclient && sleep 5 || true
            if [ -n "$(ps -A | grep -w cmclient)" ]; then
                killall -9 cmclient || true
                if [ -n "$(ps -A | grep -w CMCefApp)" ]; then
                    killall -9 CMCefApp || true
                fi
            fi
        elif [ -n "$(ps -A | grep -w CMCefApp)" ]; then
            killall -9 CMCefApp || true
        fi
    elif [ -n "$(ps -A | grep -w CMCefApp)" ]; then
        killall -9 CMCefApp || true
    fi
else
    export GDK_BACKEND=x11

    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    if [ "$(basename "$SCRIPT_DIR")" = "bin" ]; then
        APP_DIR="$(dirname "$SCRIPT_DIR")"
    else
        APP_DIR="$SCRIPT_DIR"
    fi

    CMCLIENT_BIN="${APP_DIR}/cmclient"
    if [ ! -f "$CMCLIENT_BIN" ]; then
        CMCLIENT_BIN="${APP_DIR}/files/cmclient"
    fi
    if [ ! -f "$CMCLIENT_BIN" ]; then
        echo "Error: cannot find cmclient binary" >&2
        echo "Searched: ${APP_DIR}/cmclient, ${APP_DIR}/files/cmclient" >&2
        ls -la "${APP_DIR}/" >&2 || true
        exit 1
    fi

    DISTRO=$(grep "^ID=" /etc/os-release | sed "s/ID=//" | tr -d "\"")
    if [ "$DISTRO" = "ubuntu" ]; then
        export WEBKIT_DISABLE_COMPOSITING_MODE=1
    fi
    export LD_LIBRARY_PATH="${APP_DIR}:${LD_LIBRARY_PATH}"
    "$CMCLIENT_BIN" "$@"
fi
EOF
chmod +x "$SCRIPT"
echo "Done."
'
