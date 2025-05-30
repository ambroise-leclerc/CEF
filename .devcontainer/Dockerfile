FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Install build dependencies (without X11)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ninja-build \
        wget \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install CMake 3.27.9
RUN wget -qO- https://github.com/Kitware/CMake/releases/download/v3.27.9/cmake-3.27.9-linux-x86_64.tar.gz | tar --strip-components=1 -xz -C /usr/local
