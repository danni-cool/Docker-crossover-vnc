# Using phusion/baseimage as base image and VNC
FROM phusion/baseimage:noble-1.0.0

USER root

ENV DISPLAY=":1"
ENV USER="crossover"
ENV UID=1001
ENV GID=1001
ENV HOME=/home/${USER}
ENV INSTALLDIR=/opt/cxoffice
ARG vnc_password=""
EXPOSE 5901 6080

ADD xstartup ${HOME}/.vnc/

RUN /bin/dbus-uuidgen --ensure
RUN groupadd -g ${GID} ${USER}
RUN useradd -g ${GID} -u ${UID} -r -d ${HOME} -s /bin/bash ${USER}
RUN echo "root:root" | chpasswd
# set password of ${USER} to ${USER}
RUN echo "${USER}:${USER}" | chpasswd

RUN apt-get update && \
    apt-get install -y --no-install-recommends tigervnc-standalone-server x11-xserver-utils xvfb x11-apps xterm sudo wget file zenity python3 && \
    apt-get install -y --no-install-recommends libfreetype6 libglib2.0-0 libice6 libsm6 libx11-6 libxext6 libgcc1 libpng16-16 libnss-mdns && \
    echo "${USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    apt-get install -y git build-essential gcc-multilib && \
    apt-get install -y xvfb

# 克隆libfaketime代码库并安装
RUN git clone -b v0.9.6 https://github.com/wolfcw/libfaketime.git /tmp/libfaketime && \
    cd /tmp/libfaketime && \
    export CFLAGS="-m32 -Wno-error=misleading-indentation -Wno-error=nonnull-compare -Wno-error=format-truncation" && \
    export LDFLAGS="-m32" && \
    make && make install

# 下载和设置noVNC
RUN wget https://github.com/novnc/noVNC/archive/v1.3.0.tar.gz -O /tmp/noVNC.tar.gz && \
    tar -zxvf /tmp/noVNC.tar.gz -C /opt && \
    git clone https://github.com/novnc/websockify /opt/noVNC-1.3.0/utils/websockify && \
    mv /opt/noVNC-1.3.0/vnc_lite.html /opt/noVNC-1.3.0/index.html

# 清理和删除不需要的软件包
RUN apt-get remove -y git build-essential gcc-multilib && \
    rm -rf /tmp/libfaketime && rm -f /tmp/noVNC.tar.gz && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN /bin/echo "@`date \"+%F %T\"`" > /etc/faketimerc

RUN touch ${HOME}/.vnc/passwd ${HOME}/.Xauthority

ADD wechat ${HOME}

RUN chown -R ${UID}:${GID} ${HOME} && \
    chmod 775 ${HOME}/.vnc/xstartup && \
    chmod 600 ${HOME}/.vnc/passwd && \
    mkdir -p ${INSTALLDIR} && \
    chown -R ${UID}:${GID} ${INSTALLDIR}

WORKDIR ${HOME}

# 添加 CrossOver 安装包
ADD installer/cross-over-24.0.2.bin /tmp/install-crossover.bin

# 使用 xvfb-run 来运行 CrossOver 安装程序
RUN chmod +x /tmp/install-crossover.bin && \
    xvfb-run /tmp/install-crossover.bin --i-agree-to-all-licenses --destination ${INSTALLDIR} --noreadme --noprompt --nooptions && \
    rm -f /tmp/install-crossover.bin

ADD entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

USER ${USER}

RUN /bin/echo -e 'alias ll="ls -last"' >> ${HOME}/.bashrc
# Always run the WM last!
RUN /bin/echo -e "export DISPLAY=${DISPLAY}"  >> ${HOME}/.vnc/xstartup
RUN /bin/echo -e "[ -r ${HOME}/.Xresources ] && xrdb ${HOME}/.Xresources\nxsetroot -solid grey"  >> ${HOME}/.vnc/xstartup
RUN /bin/echo -e "/opt/noVNC-1.3.0/utils/novnc_proxy --listen 6080 --vnc 127.0.0.1:5901 &"  >> ${HOME}/.vnc/xstartup
RUN /bin/echo -e "${INSTALLDIR}/bin/crossover" >> ${HOME}/.vnc/xstartup

# 保持容器运行
RUN /bin/echo -e "tail -f /dev/null" >> ${HOME}/.vnc/xstartup
