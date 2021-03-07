#FROM nvidia/cuda-ppc64le:11.0-base-ubuntu18.04
# Build tools 
FROM ppc64le/ubuntu:18.04
MAINTAINER Ruzhu Chen "ruzhuchen@us.ibm.com"

ENV HOME /root
ADD https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-ppc64le.sh /root/
ADD https://golang.org/dl/go1.16.linux-ppc64le.tar.gz /root/
ADD https://get.helm.sh/helm-v3.5.2-linux-ppc64le.tar.gz /root/
RUN apt update && apt install -y wget 
RUN echo "deb https://oplab9.parqtec.unicamp.br/pub/repository/debian/ ./" >>/etc/apt/sources.list
RUN cd /root && wget https://oplab9.parqtec.unicamp.br/pub/key/openpower-gpgkey-public.asc
RUN apt install -y ca-certificates gnupg gnupg2 gnupg1 ruby ruby-dev rubygems build-essential \
   && apt-key add /root/openpower-gpgkey-public.asc
# install cmake, make, ninja and docker with systemd driver
RUN apt-get update \
   && apt-get install -y systemd wget vim conntrack iptables iproute2 ethtool socat util-linux mount ebtables udev kmod \
   && apt-get install -y  libseccomp2 g++-8 pigz bash curl rsync nfs-common libtool cmake automake autoconf make ninja-build unzip \
   && find /lib/systemd/system/sysinit.target.wants/ -name "systemd-tmpfiles-setup.service" -delete \
   && rm -f /lib/systemd/system/multi-user.target.wants/* \
   && rm -f /etc/systemd/system/*.wants/* \
   && rm -f /lib/systemd/system/local-fs.target.wants/* \
   && rm -f /lib/systemd/system/sockets.target.wants/*udev* \
   && rm -f /lib/systemd/system/sockets.target.wants/*initctl* \
   && rm -f /lib/systemd/system/basic.target.wants/* \
   && echo "ReadKMsg=no" >> /etc/systemd/journald.conf \
   && ln -fs "$(which systemd)" /sbin/init

# setting default GCC compiler to 8.4.0
RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-8 1000 \
   && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 1000 \
   && update-alternatives --config gcc \
   && update-alternatives --config g++

# install golang com[iler
RUN cd /root/ \
  && tar xvzf go1.16.linux-ppc64le.tar.gz \
  && mv go /usr/local/

#install minikube and docker-ce and bazel compiler for build proxy envoy with dependencies
RUN apt-get install -y docker-ce conntrack minikube kubectl bazel go-bindata
RUN cd /root \
  && export RT_CONDA_PATH=/opt/miniconda3  \
  && export IBM_POWERAI_LICENSE_ACCEPT=yes \
  && bash Miniconda3-latest-Linux-ppc64le.sh -b -p $RT_CONDA_PATH  \
  && bash -c "source $RT_CONDA_PATH/bin/activate \
  && conda update -yq conda \
  && conda config --add channels default \
  && conda config --add channels conda-forge \
  && conda config --add channels https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda \
  && conda create -yqp /opt/kubeflow python=3.7 \
  && conda activate /opt/kubeflow \
  && conda install -yq kfp \
  && conda install -yq fmt spdlog abseil-cpp gn \
  && conda clean -y --all" 

# install helm, fpm and ruby gem commands
RUN cd /root/ && tar xvzf helm-v3.5.2-linux-ppc64le.tar.gz && cp linux-ppc64le/helm /usr/local/bin/
RUN echo "source /opt/miniconda3/bin/activate" > ~/.bashrc
RUN echo "conda activate /opt/kubeflow" >> ~/.bashrc
RUN echo "export PATH=\$PATH:/usr/local/go/bin" >>~/.bashrc
RUN echo "alias ls=\"ls --color=always\"" >>~/.bashrc
RUN cp -fr /opt/kubeflow/include/google /usr/include \
  && cp -fr /opt/kubeflow/include/fmt /usr/include \
  && cp -fr /opt/kubeflow/include/spdlog /usr/include \
  && cp -fr /opt/kubeflow/include/absl /usr/include 
RUN gem install --no-document fpm

RUN  rm -f /root/Miniconda3-latest-Linux-ppc64le.sh \ 
  && rm -f /root/go1.16.linux-ppc64le.tar.gz \
  && rm -f /root/helm-v3.5.2-linux-ppc64le.tar.gz \
  && rm -fr /root/linux-ppc64le \
  && rm -f /root/openpower-gpgkey-public.asc 

CMD ["/sbin/init"]
