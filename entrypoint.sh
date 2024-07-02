#!/bin/bash

[ -z "${DISPLAY}" ] || /usr/bin/vncserver -kill ${DISPLAY}
sudo rm -f /tmp/.X*-lock /tmp/.X11-unix/X*

sleep 3

if [ -z "$vnc_password" ]; then
    /usr/bin/vncserver -geometry 1920x1080 -fg -SecurityTypes None,TLSNone
else
    /usr/bin/vncserver -geometry 1920x1080 -fg
fi

# 启动 CrossOver
${INSTALLDIR}/bin/crossover &

# 启动 noVNC 服务器
/opt/noVNC-1.3.0/utils/novnc_proxy --listen 6080 --vnc 127.0.0.1:5901 &

# 保持容器运行
tail -f /dev/null
