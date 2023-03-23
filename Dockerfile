FROM ubuntu:20.04 as prepare

ENV TZ=Europe
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt update
RUN apt install -y \
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
ENV PATH="$PATH:/usr/local/USD/bin"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/USD/lib"
ENV PYTHONPATH="$PYTHONPATH:/usr/local/USD/lib/python"

WORKDIR /opt/
