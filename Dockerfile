# Use NVIDIA’s CUDA-enabled base image for Jetson devices
FROM nvcr.io/nvidia/l4t-base:r32.7.1

# Set working directory
WORKDIR /novanet

# Install dependencies and Jetson SDK
RUN apt update && apt install -y \
    build-essential \
    git \
    cmake \
    curl \
    jq \
    python3-pip \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install NVIDIA Jetson dependencies
RUN apt update && apt install -y \
    nvidia-jetpack \
    cuda-toolkit-10-2 \
    libcudnn8 \
    tensorrt \
    libnvinfer7 \
    libnvinfer-plugin7 \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies for AI Validator Selection
RUN pip3 install numpy pycuda tensorrt

# Set environment variables for CUDA and TensorRT
ENV PATH=/usr/local/cuda/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Copy NovaNet validator source code
COPY . /novanet

# Copy AI model (must be added to the NovaNet repo or built inside the container)
COPY validator_model.trt /novanet/

# Build the validator
RUN make build

# Start the NovaNet validator with GPU acceleration and AI inference
CMD ["python3", "/novanet/run_validator.py"]
