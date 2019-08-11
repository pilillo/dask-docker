FROM nvidia/cuda:10.0-cudnn7-runtime-ubuntu18.04

ARG MINICONDA_VERSION=4.6.14

USER root

ENV DEBIAN_FRONTEND noninteractive

ENV CONDA_DIR=/opt/conda
ENV PATH $CONDA_DIR/bin:$PATH

ENV MINICONDA_VERSION $MINICONDA_VERSION

RUN apt-get update && apt-get install -yq --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    wget \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN [ ! -z http_proxy ] && echo -e "proxy_servers:\n  http: $http_proxy\n  https: $https_proxy\nssl_verify: False\n" > $HOME/.condarc

RUN cd /tmp && \
    mkdir -p $CONDA_DIR && \
    wget https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    echo "718259965f234088d785cad1fbd7de03 *Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh" | md5sum -c - && \
    /bin/bash Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -f -b -p ${CONDA_DIR} && \
    rm Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    conda config --system --prepend channels conda-forge && \
    conda config --system --set auto_update_conda false && \
    conda config --system --set show_channel_urls true && \
    conda update --all && \
    conda update conda && \
    conda clean -tipsy


RUN conda install --yes --freeze-installed \
    -c conda-forge \
    python-blosc \
    cytoolz \
    dask==2.0.0 \
    nomkl \
    numpy==1.16.2 \
    pandas==0.24.2 \
    tini==0.18.0 \
    # packages for rapidsai and cudf
    && conda install --yes --freeze-installed \
    -c nvidia -c rapidsai -c numba -c conda-forge -c pytorch -c defaults \
    numba=0.45.1 \
    cudf=0.8 \
    cuml=0.8 \
    cugraph=0.8 \
    python=3.7 \
    cudatoolkit=10.0 \
    # dask wrappers
    && conda install --yes --freeze-installed \
    -c rapidsai \
    dask-cuda=0.8.0 \
    dask-cudf=0.8.0 \
    # cleanup   
    && conda clean -tipsy \
    && find /opt/conda/ -type f,l -name '*.a' -delete \
    && find /opt/conda/ -type f,l -name '*.pyc' -delete \
    && find /opt/conda/ -type f,l -name '*.js.map' -delete \
    && find /opt/conda/lib/python*/site-packages/bokeh/server/static -type f,l -name '*.js' -not -name '*.min.js' -delete \
    && rm -rf /opt/conda/pkgs

COPY prepare.sh /usr/bin/prepare.sh

RUN mkdir /opt/app

ENTRYPOINT ["tini", "-g", "--", "/usr/bin/prepare.sh"]
