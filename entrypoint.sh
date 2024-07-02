#!/bin/bash

[ -z "${DISPLAY}" ] || /usr/bin/vncserver -kill ${DISPLAY}
sudo rm -f /tmp/.X*-lock /tmp/.X11-unix/X*

sleep 3

if [ -z "$vnc_password" ]; then
    /usr/bin/vncserver -geometry 1920x1080 -fg -SecurityTypes None,TLSNone
else
    /usr/bin/vncserver -geometry 1920x1080 -fg
fi