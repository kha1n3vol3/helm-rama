FROM ubuntu:24.10

RUN apt-get update && \
    apt-get install -y \
        unzip \
        openjdk-17-jdk \
        curl \
        nano \
        python3 && \
    ln -s /usr/bin/python3 /usr/bin/python

RUN useradd --create-home --shell /bin/bash rama

# Download the Rama release archive into the rama user's home directory
USER rama
WORKDIR /home/rama
RUN curl -LsS https://redplanetlabs.s3.us-west-2.amazonaws.com/rama/rama-1.1.0.zip \
      -o rama-1.1.0.zip

# Switch back to root for any further instructions
USER root
