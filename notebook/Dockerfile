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

ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"

ENV DEBIAN_FRONTEND noninteractive

ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER=$NB_USER \
    NB_UID=$NB_UID \
    NB_GID=$NB_GID \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home/$NB_USER

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

#RUN mkdir -p /opt/app

# notebook stuff

#USER root
ENV DEBIAN_FRONTEND noninteractive

ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"

ENV NB_PREFIX /

ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home/$NB_USER

RUN apt-get update && apt-get install -yq --no-install-recommends \
  apt-transport-https \
  build-essential \
  bzip2 \
  ca-certificates \
  curl \
  g++ \
  git \
  gnupg \
  graphviz \
  locales \
  lsb-release \
  openssh-client \
  sudo \
  unzip \
  vim \
  wget \
  zip \
  emacs \
  && apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Create jovyan user with UID=1000 and in the 'users' group
# but allow for non-initial launches of the notebook to have
# $HOME provided by the contents of a PV
RUN useradd -M -s /bin/bash -N -u $NB_UID $NB_USER && \
    chown -R ${NB_USER}:users /usr/local/bin && \
    mkdir -p $CONDA_DIR && \
    chown $NB_USER:$NB_GID $CONDA_DIR && \
    chmod g+w /etc/passwd && \    
    mkdir -p $HOME && \
    chgrp $NB_GID $HOME && chmod g+rwX $HOME


RUN mkdir /home/$NB_USER/work && \
    chown $NB_USER:$NB_GID /home/$NB_USER

#USER $NB_USER
WORKDIR $HOME

# Install Jupyter Notebook, Lab, and Hub
# Generate a notebook server config
# Cleanup temporary files
# Correct permissions
# Do all this in a single RUN command to avoid duplicating all of the
# files across image layers when the permissions change
RUN conda install  --yes --freeze-installed \
    -c nvidia -c rapidsai -c numba -c conda-forge -c pytorch -c defaults \
    'notebook=6.0.0' \
    'jupyterhub=1.0.0' \
    'jupyterlab=1.0.4' \
    bokeh \
    dask-labextension \
    ipython=${IPYTHON_VERSION} \     
    matplotlib \
    networkx \
    nodejs \
    scikit-learn \
    scipy \
    seaborn \
    && conda clean -afy \
    && chmod -R ugo+w /opt/conda \
    && jupyter labextension install dask-labextension \
    && conda clean --all -f -y && \
    npm cache clean --force && \
    jupyter notebook --generate-config && \
    rm -rf $CONDA_DIR/share/jupyter/lab/staging && \
    rm -rf /home/$NB_USER/.cache/yarn

#USER root

# Create the /opt/app directory, and assert that Jupyter's NB_UID/NB_GID values
# haven't changed. 
RUN mkdir -p /opt/app \
    && if [ "$NB_UID" != "1000" ] || [ "$NB_GID" != "100" ]; then \
        echo "Jupyter's NB_UID/NB_GID changed, need to update the Dockerfile"; \ 
        exit 1; \
    fi

# Copy over the example as NB_USER. Unfortuantely we can't use $NB_UID/$NB_GID
# in the `--chown` statement, so we need to hardcode these values.
COPY --chown=1000:100 examples/ /home/$NB_USER/examples
COPY prepare.sh /usr/bin/prepare.sh

USER $NB_USER
EXPOSE 8888

ENTRYPOINT ["tini", "--", "/usr/bin/prepare.sh"]
#CMD ["start.sh", "jupyter", "lab"]
CMD ["sh","-c", "jupyter lab --notebook-dir=$HOME --ip=0.0.0.0 --no-browser --allow-root --port=8888 --NotebookApp.token='' --NotebookApp.password='' --NotebookApp.allow_origin='*' --NotebookApp.base_url=${NB_PREFIX}"]
