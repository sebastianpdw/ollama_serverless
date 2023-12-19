# Stage 1: Downloading files
FROM ollama/ollama as downloader

ARG MODEL_NAME

# Copy the startup script into the image
COPY startup.sh /startup.sh

# Make sure the script is executable
RUN chmod +x /startup.sh

# Run the initialization script to perform the pull operation
RUN /startup.sh $MODEL_NAME

# Stage 2: Set up ollama image
FROM ollama/ollama

# Copy the model files
COPY --from=downloader /root/.ollama/ /root/.ollama/
# Copy the ollama binary
COPY --from=downloader /bin/ollama /bin/ollama

# Set variables for ollama
ENV HOME=/root
RUN chmod 777 /root

# Set up AWS Lambda environment (from Dockerfile in https://github.com/aws/aws-lambda-base-images.git)
# Install git, git-lfs, xz-utils, and tar
RUN apt-get update && apt-get install -y \
    git \
    git-lfs \
    xz-utils \
    tar \
    python3-pip \
    rsync \
    && rm -rf /var/lib/apt/lists/*

# Configure git lfs
RUN git lfs install

# Clone the specific git repository
RUN git clone https://github.com/aws/aws-lambda-base-images.git
WORKDIR ./aws-lambda-base-images/
RUN git checkout python3.12

# Set the working directory to the cloned directory
WORKDIR ./x86_64/

# Unzip all .xz and .tar files in the directory
RUN mkdir -p ./unzipped
RUN for file in *.xz; do \
        [ -e "$file" ] && unxz -k "$file" && mv "${file%.*}" unzipped/ || echo "No .xz files found or error extracting $file"; \
    done \
    && for file in ./unzipped/*.tar; do \
        [ -e "$file" ] && tar -xvf "$file" -C unzipped/ || echo "No .tar files found or error extracting $file"; \
    done \
    && rm -rf ./unzipped/*.tar
WORKDIR ./unzipped/

# Copy only relevant directories
RUN cp -r ./usr/local/bin/ /usr/local/bin/
RUN cp -r ./var/lang/ /var/lang/
RUN cp -r ./var/runtime/ /var/runtime/

# Copy the lambda-entrypoint.sh script
RUN mkdir /var/task/
RUN cp ./lambda-entrypoint.sh /var/task/lambda-entrypoint.sh

# Set environment variables and entrypoint for AWS Lambda
ENV LANG=en_US.UTF-8
ENV TZ=:/etc/localtime
ENV PATH=/var/lang/bin:/usr/local/bin:/usr/bin/:/bin:/opt/bin:$PATH
ENV LD_LIBRARY_PATH=/var/lang/lib:/lib64:/usr/lib64:/var/runtime:/var/runtime/lib:/var/task:/var/task/lib:/opt/lib
ENV LAMBDA_TASK_ROOT=/var/task
ENV LAMBDA_RUNTIME_DIR=/var/runtime
WORKDIR /var/task/
ENTRYPOINT ["./lambda-entrypoint.sh"]

# Copy the handler function for AWS Lambda
COPY ./function.py .

# Install dependencies for handler function
RUN pip3 install requests

# Set the handler function
CMD ["function.lambda_handler"]