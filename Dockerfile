# Build the docker image:
# docker build --rm -t ababak/usd-build-ubuntu:1.3 .
FROM ubuntu:22.04 as prepare

ENV TZ=Europe
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && \
    apt-get install -y software-properties-common wget && \
    # Obtain a copy of the signing key
    wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | \
    gpg --dearmor - | \
    tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null && \
    # Add the repository to your sources list
    apt-add-repository 'deb https://apt.kitware.com/ubuntu/ jammy main' && \
    apt-get update

RUN apt-get install -y \
    build-essential \
    cmake \
    git \
    libglew-dev \
    libglib2.0-0 \
    libx11-dev \
    python3 \
    python3-pip \
    pkg-config
RUN pip3 install PySide2 PyOpenGL jinja2

# BUILD
FROM prepare as build
RUN git clone https://github.com/PixarAnimationStudios/USD
RUN python3 USD/build_scripts/build_usd.py --ptex --openvdb --openimageio --opencolorio --hdf5 --alembic /usr/local/USD

# RESULT
FROM prepare as result
COPY --from=build /usr/local/USD/bin /usr/local/USD/bin
COPY --from=build /usr/local/USD/lib /usr/local/USD/lib
COPY --from=build /usr/local/USD/plugin /usr/local/USD/plugin
ENV PATH="$PATH:/usr/local/USD/bin"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/USD/lib"
ENV PYTHONPATH="$PYTHONPATH:/usr/local/USD/lib/python"

WORKDIR /opt/
