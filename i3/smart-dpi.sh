#!/bin/bash

INTERNAL="eDP-1"
HDMI="HDMI-1"
DP="DP-3"

log() {
    echo "[xrandr-setup] $1"
}

# DPI scaling
apply_internal_hidpi() {
    xrdb -merge <<< "Xft.dpi: 165"
    export XFT_DPI=165
    export GDK_SCALE=1
    export GDK_DPI_SCALE=1
    export QT_SCALE_FACTOR=1
    export QT_AUTO_SCREEN_SCALE_FACTOR=1
}

apply_normal_dpi() {
    xrdb -merge <<< "Xft.dpi: 96"
    export XFT_DPI=96
    export GDK_SCALE=1
    export GDK_DPI_SCALE=1
    export QT_SCALE_FACTOR=1
    export QT_AUTO_SCREEN_SCALE_FACTOR=0
}

# Check which monitors are connected
DP_CONNECTED=$(xrandr | grep "^$DP connected")
HDMI_CONNECTED=$(xrandr | grep "^$HDMI connected")

if [[ -n "$DP_CONNECTED" ]]; then
    # Get DP resolution
    DP_MODE=$(xrandr | grep -A1 "^$DP connected" | tail -n1 | awk '{print $1}')
    if [[ -z "$DP_MODE" ]]; then
        log "Failed to get DP resolution."
        exit 1
    fi

    if [[ -n "$HDMI_CONNECTED" ]]; then
        # Get HDMI resolution
        HDMI_MODE=$(xrandr | grep -A1 "^$HDMI connected" | tail -n1 | awk '{print $1}')
        if [[ -z "$HDMI_MODE" ]]; then
            log "Failed to get HDMI resolution."
            exit 1
        fi

        # Calculate HDMI position (to the right of DP)
        HDMI_X_POS=$(echo "$DP_MODE" | cut -d'x' -f1)

        xrandr --output "$INTERNAL" --off \
               --output "$DP" --primary --mode "$DP_MODE" --pos 0x0 --rotate normal \
               --output "$HDMI" --mode "$HDMI_MODE" --pos "${HDMI_X_POS}x0" --rotate normal

        log "Setup: DP (left, primary) + HDMI (right)"
    else
        xrandr --output "$INTERNAL" --off \
               --output "$DP" --primary --auto --pos 0x0 --rotate normal \
               --output "$HDMI" --off

        log "Setup: DP only"
    fi
    apply_normal_dpi

elif [[ -n "$HDMI_CONNECTED" ]]; then
    xrandr --output "$INTERNAL" --off \
           --output "$HDMI" --primary --auto --pos 0x0 --rotate normal \
           --output "$DP" --off

    log "Setup: HDMI only"
    apply_normal_dpi

else
    xrandr --output "$HDMI" --off \
           --output "$DP" --off \
           --output "$INTERNAL" --auto --primary

    log "Setup: Internal display only"
    apply_internal_hidpi
fi

