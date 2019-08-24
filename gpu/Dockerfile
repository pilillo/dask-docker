ARG PYTHON_VERSION=3.7
ARG CUDA_VERSION=10.0
ARG OS_TYPE=ubuntu18.04
ARG MINICONDA_VERSION=4.6.14
ARG DASK_VERSION=">2.2.0"
ARG NUMPY_VERSION=1.16.2
ARG PANDAS_VERSION=0.24.2
ARG XGBOOST_VERSION=0.90
ARG NUMBA_VERSION=0.45.1
ARG RAPIDS_CONDA_VERSION_SPEC=0.9*

FROM nvidia/cuda:${CUDA_VERSION}-cudnn7-runtime-${OS_TYPE} as base

ARG PYTHON_VERSION
ARG MINICONDA_VERSION
ARG CUDA_VERSION
ARG OS_TYPE
ARG DASK_VERSION
ARG PANDAS_VERSION
ARG NUMPY_VERSION
ARG XGBOOST_VERSION
ARG NUMBA_VERSION
ARG RAPIDS_CONDA_VERSION_SPEC


USER root

ENV DEBIAN_FRONTEND noninteractive

ENV CONDA_DIR=/opt/conda
ENV PATH $CONDA_DIR/bin:$PATH

ENV MINICONDA_VERSION $MINICONDA_VERSION

RUN apt-get update; apt-get install -yq --no-install-recommends \
    ca-certificates \
    apt-transport-https \
    wget \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

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
    dask=${DASK_VERSION} \
    nomkl \
    numpy=${NUMPY_VERSION} \
    pandas=${PANDAS_VERSION} \
    tini==0.18.0 \
    # packages for rapidsai and cudf
    && conda install --yes --freeze-installed \
    -c nvidia -c rapidsai -c numba -c conda-forge -c pytorch -c defaults \
    numba=0.45.1 \
    cudf=${RAPIDS_CONDA_VERSION_SPEC} \
    cuml=${RAPIDS_CONDA_VERSION_SPEC} \
    cugraph=${RAPIDS_CONDA_VERSION_SPEC} \
    python=${PYTHON_VERSION} \
    cudatoolkit=${CUDA_VERSION} \
    dask-cuda=${RAPIDS_CONDA_VERSION_SPEC} \
    dask-cudf=${RAPIDS_CONDA_VERSION_SPEC} \
    xgboost=${XGBOOST_VERSION} \
    dask-xgboost=${DASK_XGBOOST_CONDA_VERSION_SPEC} \
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
