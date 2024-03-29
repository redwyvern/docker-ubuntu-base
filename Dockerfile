FROM ubuntu:focal
LABEL maintainer="Nick Weedon <nick@weedon.org.au>"

ARG DEBIAN_FRONTEND=noninteractive

# The timezone for the image (set to Etc/UTC for UTC)
ARG IMAGE_TZ=America/New_York

USER root

RUN mkdir -p /etc/gcrypt && echo all >>/etc/gcrypt/hwf.deny

RUN apt-get clean && apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    gnupg && \
    apt-get -q autoremove && \
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

# Configure the sources.list to point to the local cache
COPY sources.list /etc/apt

RUN wget -qO - https://artifactory.weedon.org.au/artifactory/api/gpg/key/public | apt-key add -

# Change the sources.list file to the correct distribution
RUN sed -i 's/{{dist}}/focal/g' /etc/apt/sources.list

# Install apt-utils first so that packages are configured properly
RUN apt-get clean && apt-get update && apt-get install -y --no-install-recommends \
    apt-utils && \
    apt-get -q autoremove && \
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

# Add some necessary utility packages to bootstrap the install process
RUN apt-get clean && apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    locales \
    gpg-agent \
    tzdata \
    apt-transport-https \
    ca-certificates \
    software-properties-common && \
    apt-get -q autoremove && \
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

# Add the local artifactory instance to the apt sources lists
#RUN echo deb http://artifactory.weedon.org.au/artifactory/debian-local $(lsb_release -cs) main >/etc/apt/sources.list.d/artifactory.list && \

# Add locales after locale-gen as needed
# Upgrade packages on image
# Preparations for sshd
RUN locale-gen en_US.UTF-8 &&\
    apt-get -q update &&\
    apt-get -q upgrade -y -o Dpkg::Options::="--force-confnew" --no-install-recommends &&\
    apt-get -q install -y -o Dpkg::Options::="--force-confnew"  --no-install-recommends openssh-server &&\
    apt-get -q autoremove &&\
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin &&\
    sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd &&\
    mkdir -p /var/run/sshd

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Set the timezone
# Normally this would be done via: echo ${IMAGE_TZ} >/etc/timezone && dpkg-reconfigure -f noninteractive tzdata 
# A bug in the current version of Ubuntu prevents this from working: https://bugs.launchpad.net/ubuntu/+source/tzdata/+bug/1554806
# Change this to the normal method once this is fixed.
RUN ln -fs /usr/share/zoneinfo/${IMAGE_TZ} /etc/localtime && dpkg-reconfigure -f noninteractive tzdata
