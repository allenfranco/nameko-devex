FROM python:3.9.12-slim AS base
LABEL maintainer="allenfranco@gmail.com" 

RUN apt-get update && \
    apt-get install --yes curl netcat libpq5

RUN pip3 install --upgrade pip
RUN pip3 install virtualenv

RUN virtualenv -p python3 /appenv

ENV PATH=/appenv/bin:$PATH

RUN groupadd -r nameko && useradd -r -g nameko nameko

RUN mkdir /var/nameko/ && chown -R nameko:nameko /var/nameko/

# ------------------------------------------------------------------------

FROM nameko-example-base AS builder

RUN apt-get update && \
    apt-get install --yes build-essential autoconf libtool pkg-config \
    libgflags-dev libgtest-dev clang libc++-dev automake git libpq-dev

RUN pip install auditwheel

COPY . /application

ENV PIP_WHEEL_DIR=/application/wheelhouse
ENV PIP_FIND_LINKS=/application/wheelhouse