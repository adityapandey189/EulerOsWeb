FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    python3 \
    python3-pip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --break-system-packages gdown

RUN mkdir -p /app /data/android-image

COPY start.sh /app/start.sh

RUN chmod +x /app/start.sh

ENTRYPOINT ["/app/start.sh"]