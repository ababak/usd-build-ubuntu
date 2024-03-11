# Build the docker image:
# docker build --rm -t ababak/usd-build-ubuntu:1.3 .
FROM ubuntu:23.10 as prepare

ENV TZ=Europe
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update

RUN apt-get install -y \
    build-essential \
    cmake \
    git \
    libglew-dev \
    libglib2.0-0 \
    libx11-dev \
    libxt-dev \
    python3 \
    python3-pip \
    pkg-config

# Overcome PEP 668 – Marking Python base environments as “externally managed”
RUN printf "[global]\nbreak-system-packages = true" > /etc/pip.conf
RUN pip3 install PySide2 PyOpenGL jinja2

# BUILD
FROM prepare as build
RUN git clone https://github.com/PixarAnimationStudios/USD
# Use TBB v2020.3.3 tag to overcome the gcc-13 compile error
RUN sed -i \
    's#/oneTBB/archive/refs/tags/v2020\.3\.zip#/oneTBB/archive/refs/tags/v2020\.3\.3\.zip#' \
    USD/build_scripts/build_usd.py
# Use OpenColorIO v2.3.2 tag to overcome the gcc-13 compile error
RUN sed -i \
    's#/OpenColorIO/archive/refs/tags/v2\.1\.3\.zip#/OpenColorIO/archive/refs/tags/v2\.3\.2\.zip#' \
    USD/build_scripts/build_usd.py
RUN python3 USD/build_scripts/build_usd.py \
    --ptex \
    --openvdb \
    --openimageio \
    --opencolorio \
    --hdf5 \
    --alembic \
    --no-examples \
    --no-tutorials \
    --no-docs \
    --no-usdview \
    /usr/local/USD

# RESULT
FROM prepare as result
COPY --from=build /usr/local/USD/bin /usr/local/USD/bin
COPY --from=build /usr/local/USD/lib /usr/local/USD/lib
COPY --from=build /usr/local/USD/plugin /usr/local/USD/plugin
ENV PATH="$PATH:/usr/local/USD/bin"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/USD/lib"
ENV PYTHONPATH="$PYTHONPATH:/usr/local/USD/lib/python"

WORKDIR /opt/
