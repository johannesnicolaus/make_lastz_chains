FROM continuumio/miniconda3

ARG MAKE_LASTZ_CHAINS_REF=main
ARG LASTZ_REF=master

# System deps: build tools (lastz), Python, download utils (kent binaries)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget git \
    python3 python3-pip python3-venv \
    build-essential \
    rsync unzip xz-utils bzip2 \
    && rm -rf /var/lib/apt/lists/*

RUN conda install -c conda-forge openjdk=17

# Pin Nextflow version and silence capsule logs during install
#ENV NXF_VER=20.10.0 \
#    CAPSULE_LOG=none

RUN curl -s https://get.nextflow.io | bash \
 && mv nextflow /usr/local/bin/ \
 && chmod 755 /usr/local/bin/nextflow

RUN conda install -c bioconda lastz

# && chmod -R 777 /opt/conda/share/nextflow
    
RUN python3 -m pip install --no-cache-dir uv

#RUN git clone https://github.com/hillerlab/make_lastz_chains.git \
#    && cd make_lastz_chains \
#    && uv venv \
#    && . .venv/bin/activate \
#    && uv pip install "."

# 1. Create the venv in a predictable location
RUN git clone https://github.com/hillerlab/make_lastz_chains.git \
    && cd make_lastz_chains \
    && uv venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

# 3. Install the package (uv will detect the active venv via PATH)
RUN cd make_lastz_chains && uv pip install "."

# The pipeline requires many UCSC Kent binaries,
# they can be downloaded using this script,
# unless they are already in the $PATH:
RUN cd make_lastz_chains && ./install_dependencies.py && conda install -c bioconda twobitreader

ENV PATH="/make_lastz_chains:/opt/venv/bin:$PATH"
ENV PATH="/opt/venv/bin:$PATH"
