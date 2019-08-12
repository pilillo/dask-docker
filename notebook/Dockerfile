FROM nvidia/cuda:10.0-cudnn7-runtime-ubuntu18.04

ARG MINICONDA_VERSION=4.6.14

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
RUN conda install --quiet --yes \
    'notebook=6.0.0' \
    'jupyterhub=1.0.0' \
    'jupyterlab=1.0.4' && \
    conda clean --all -f -y && \
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
