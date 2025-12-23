# Install OpenSSL 1.1 (required by Kent binaries)
RUN wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb \
    && dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb \
    && rm libssl1.1_1.1.1f-1ubuntu2_amd64.deb

# Create separate conda environment with Python 3.11 for Kent tools and dependencies
# This avoids OpenSSL conflicts with the base Python 3.13 environment
RUN conda create -n kent python=3.11 -y \
    && conda install -n kent -c bioconda -c conda-forge \
       lastz \
       twobitreader \
       ucsc-axtchain \
       ucsc-fatotwobit \
       ucsc-chainmergesort \
       ucsc-chainsort \
       ucsc-netchainsubset \
       ucsc-liftover \
       ucsc-pslsortacc \
       ucsc-chainnet \
       ucsc-netsyntenic \
       ucsc-chainantirepeat \
       ucsc-chainscore \
       ucsc-chaincleaner \
       libiconv \
       -y

RUN echo "/opt/conda/envs/kent/lib" > /etc/ld.so.conf.d/conda-kent.conf \
    && ldconfig

ENV LD_LIBRARY_PATH="/opt/conda/envs/kent/lib:${LD_LIBRARY_PATH}"

# Add Kent conda environment to PATH (comes first for priority)
ENV PATH="/opt/conda/envs/kent/bin:${PATH}"

# Install Java 17 for Nextflow in base environment
RUN conda install -c conda-forge openjdk=17

# Install Nextflow
ENV CAPSULE_LOG=none
RUN curl -s https://get.nextflow.io | bash \
 && mv nextflow /usr/local/bin/ \
 && chmod 755 /usr/local/bin/nextflow

# Install uv
RUN python3 -m pip install --no-cache-dir uv

# Create the venv in a predictable location
RUN git clone https://github.com/hillerlab/make_lastz_chains.git \
    && cd make_lastz_chains \
    && uv venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

# Install the package (uv will detect the active venv via PATH)
RUN cd make_lastz_chains && uv pip install "."

# Install any remaining dependencies not in conda
# The install_dependencies.py will skip tools already in PATH from conda
RUN cd make_lastz_chains \
    && ./install_dependencies.py \
    && chmod -R 755 /make_lastz_chains/HL_kent_binaries

ENV PATH="/make_lastz_chains:/opt/venv/bin:$PATH"

WORKDIR /work
