FROM ubuntu:24.10

RUN apt-get update && \
    apt-get install -y \
        unzip \
        openjdk-17-jdk \
        curl \
        nano \
        python3 && \
    ln -s /usr/bin/python3 /usr/bin/python

RUN mkdir -p /home/rama

COPY rama-<version>.zip /home/rama/
