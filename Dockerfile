FROM debian:buster-slim

RUN set -ex \
    # Official Mopidy install for Debian/Ubuntu along with some extensions
    # (see https://docs.mopidy.com/en/latest/installation/debian/ )
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        ca-certificates \
	wget \
        dumb-init \
        gnupg \
        python3-crypto \
        python3-distutils \
        python3-pip \
        libxml2-dev \
	libxslt-dev \
	gstreamer1.0-plugins-bad \
	pulseaudio

RUN set -ex \
 && wget -q -O -  https://apt.mopidy.com/mopidy.gpg | apt-key add - \
 && wget -q -O -  https://apt.mopidy.com/mopidy.list > /etc/apt/sources.list.d/mopidy.list \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        mopidy \
        mopidy-mpd \
        mopidy-local \
	mopidy-soundcloud \
	mopidy-spotify

RUN set -ex \
 && apt-get install -y \
	python3-lxml \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache \
 && python3 -m pip install Mopidy-YouTube Mopidy-Iris Mopidy-Pandora Mopidy-MusicBox-Webclient Mopidy-YTMusic

RUN set -ex \
 && mkdir -p /var/lib/mopidy/.config \
 && ln -s /config /var/lib/mopidy/.config/mopidy

# Start helper script.
COPY entrypoint.sh /entrypoint.sh

# Default configuration.
COPY mopidy.conf /config/mopidy.conf

COPY pulse-client.conf /etc/pulse/client.conf

ENV UNAME=mopidy

# Set up the user
RUN export UNAME=$UNAME UID=1000 GID=1000 && \
    mkdir -p "/home/${UNAME}" && \
    echo "${UNAME}:x:${UID}:${GID}:${UNAME} User,,,:/home/${UNAME}:/bin/bash" >> /etc/passwd && \
    echo "${UNAME}:x:${UID}:" >> /etc/group && \
    mkdir -p /etc/sudoers.d && \
    echo "${UNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${UNAME} && \
    chmod 0440 /etc/sudoers.d/${UNAME} && \
    chown ${UID}:${GID} -R /home/${UNAME} && \
    gpasswd -a ${UNAME} audio

ENV HOME /home/mopidy
RUN set -ex \
 && chown mopidy:audio -R $HOME /entrypoint.sh \
 && chmod go+rwx -R $HOME /entrypoint.sh

# Runs as mopidy user by default.
USER mopidy

# Basic check,
RUN /usr/bin/dumb-init /entrypoint.sh /usr/bin/mopidy --version

VOLUME ["/var/lib/mopidy/local", "/var/lib/mopidy/media"]

EXPOSE 6600 6680 5555/udp

ENTRYPOINT ["/usr/bin/dumb-init", "/entrypoint.sh"]
CMD ["/usr/bin/mopidy"]

