ARG CUDA_VERSION=12.3.0

FROM docker.io/nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu22.04

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
      libgl1-mesa-glx libglib2.0-0 libsm6 libxrender1 libxext6 \
      git python3 python3-pip && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/lllyasviel/Fooocus /app
WORKDIR /app

RUN pip install --no-cache -r requirements_versions.txt
RUN pip install --no-cache torch==2.1.0 torchvision==0.16.0 \
    --extra-index-url "https://download.pytorch.org/whl/cu121"

VOLUME /app/models

ENTRYPOINT [ "python3", "launch.py", "--listen" ]