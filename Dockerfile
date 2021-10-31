# syntax=docker/dockerfile:1
FROM ubuntu:20.04

ARG UID=1000
ARG GID=1000
ENV DEBIAN_FRONTEND=noninteractive 

RUN apt-get update \
    && apt-get -y --no-install-recommends install \
        gnuplot \
        graphviz \
        imagemagick \
        build-essential \
        libcgal-dev \
        git-annex \
        bc \
        libclang-dev \
        ca-certificates \
        && apt-get clean

ARG ZOLA_VERSION=v0.14.1
ARG ZOLA_TARGET=x86_64-unknown-linux-gnu
ARG ZOLA=zola-$ZOLA_VERSION-$ZOLA_TARGET
RUN curl -L https://github.com/getzola/zola/releases/download/$ZOLA_VERSION/$ZOLA.tar.gz -o zola.tar.gz \
    && tar xf zola.tar.gz -C /usr/bin/

RUN curl -L "http://www.fmwconcepts.com/imagemagick/downloadcounter.php?scriptname=feather&dirname=feather" -o /usr/bin/feather \
    && chmod +x /usr/bin/feather

RUN groupadd -g $GID -o dva \
    && useradd -m -u $UID -g $GID -o -s /bin/bash dva \
    && usermod -aG sudo -aG plugdev dva \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /dva
USER dva

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

RUN mkdir ~/.cargo/git ~/.cargo/registry
ENV PATH=/home/dva/.cargo/bin:$PATH
