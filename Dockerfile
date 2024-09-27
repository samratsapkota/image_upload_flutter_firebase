# Use the official Dart image as the base image
FROM dart:stable AS build

# Install required packages
RUN apt-get update && apt-get install -y \
    git \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Set the Flutter version you want to install
ENV FLUTTER_VERSION 3.10.5

# Download and install Flutter SDK
RUN wget https://storage.googleapis.com/download/flutter_infra/releases/stable/linux/flutter_linux_$FLUTTER_VERSION-stable.tar.xz \
    && tar xf flutter_linux_$FLUTTER_VERSION-stable.tar.xz -C /opt/ \
    && rm flutter_linux_$FLUTTER_VERSION-stable.tar.xz

# Set the Flutter path
ENV PATH="$PATH:/opt/flutter/bin"

# Enable Flutter's web support
RUN flutter channel stable \
    && flutter upgrade \
    && flutter config --enable-web

# Set the working directory
WORKDIR /app

# Command to keep the container running
CMD ["flutter", "--version"]
