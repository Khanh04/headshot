FROM nvidia/cuda:12.2.0-runtime-ubuntu20.04 AS base-image
# ensure local python is preferred over distribution python
ENV PATH /usr/local/bin:$PATH
ARG DEBIAN_FRONTEND=noninteractive

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8
# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 23.0.1
# https://github.com/docker-library/python/issues/365
ENV PYTHON_SETUPTOOLS_VERSION 65.5.1
# https://github.com/pypa/get-pip
ENV PYTHON_GET_PIP_URL https://github.com/pypa/get-pip/raw/0d8570dc44796f4369b652222cf176b3db6ac70e/public/get-pip.py
ENV PYTHON_GET_PIP_SHA256 96461deced5c2a487ddc65207ec5a9cffeca0d34e7af7ea1afc470ff0d746207
ENV GPG_KEY A035C8C19219BA821ECEA86B64E628F8D684696D
ENV LD_LIBRARY_PATH=/usr/local/lib64 
ENV PYTHON_VERSION 3.10.4

RUN apt-get update && apt-get upgrade --yes 
# runtime dependencies
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		ca-certificates \
		netbase \
		tzdata \
		libgl1 \
		libglib2.0-0 \
		libopencv-dev \
		python3-opencv \
		software-properties-common \
		libstdc++6; \
	add-apt-repository ppa:ubuntu-toolchain-r/test; \
	apt upgrade libstdc++6 -y; \
	apt-get upgrade -y; \
	apt-get dist-upgrade; \
	rm -rf /var/lib/apt/lists/*

COPY ./scripts/install.sh /
RUN chmod +x /install.sh && /install.sh

WORKDIR /app/
COPY requirements.txt /app/
RUN pip3 install -r requirements.txt
COPY . /app/

# --- Image 1: Uvicorn App ---
FROM base-image AS uvicorn-app
CMD ["uvicorn", "app:app", "--host", "0.0.0.0"]


# --- Image 2: Runpod ---
FROM base-image AS runpod-app
CMD ["python", "run_serverless.py"]