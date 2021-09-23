# syntax=docker/dockerfile:1
FROM ubuntu:20.04

ARG UID=1000
ARG GID=1000
ENV DEBIAN_FRONTEND=noninteractive 

RUN apt-get update \
    && apt-get -y --no-install-recommends install \
        gnuplot \
        graphviz \
        libimage-size-perl \
        imagemagick \
        libwebp-dev \
        libdbd-sqlite3-perl \
        build-essential \
        sqlite3 \
        libgraphicsmagick1-dev \
        graphicsmagick-libmagick-dev-compat \
        libmagickcore-6-arch-config \
        libfile-slurp-unicode-perl \
        libencode-perl \
        libcgal-dev \
        libmoosex-getopt-perl \
        git-annex \
        libjson-perl \
        haskell-stack \
        python3 \
        python3-pip \
        bc \
        && apt-get clean

RUN cpan install Lingua:EN:Titlecase:HTML

RUN python3 -m pip install \
    python-frontmatter \
    pillow \
    markdown

ARG ZOLA_VERSION=v0.14.1
ARG ZOLA_TARGET=x86_64-unknown-linux-gnu
ARG ZOLA=zola-$ZOLA_VERSION-$ZOLA_TARGET
RUN curl -L https://github.com/getzola/zola/releases/download/$ZOLA_VERSION/$ZOLA.tar.gz -o zola.tar.gz \
    && tar xf zola.tar.gz -C /usr/bin/

RUN curl -L "http://www.fmwconcepts.com/imagemagick/downloadcounter.php?scriptname=feather&dirname=feather" -o /usr/bin/feather \
    && chmod +x /usr/bin/feather

RUN stack upgrade

RUN groupadd -g $GID -o dva \
    && useradd -m -u $UID -g $GID -o -s /bin/bash dva \
    && usermod -aG sudo -aG plugdev dva \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /dva
USER dva