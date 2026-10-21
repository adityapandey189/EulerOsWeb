FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH="${PATH}:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/opt/android-sdk/emulator"

# Base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    python3 \
    python3-pip \
    ca-certificates \
    openjdk-17-jre \
    libgl1 \
    libpulse0 \
    libnss3 \
    libx11-6 \
    libxcomposite1 \
    libxcursor1 \
    libxi6 \
    libxrandr2 \
    libxtst6 \
    libxdamage1 \
    libxfixes3 \
    libasound2t64 \
    && rm -rf /var/lib/apt/lists/*

# Used for downloading the EulerOS image from Google Drive
RUN pip3 install --break-system-packages gdown

# Create required directories
RUN mkdir -p \
    /app \
    /data/android-image \
    ${ANDROID_SDK_ROOT}/cmdline-tools

# Install Android command-line tools
RUN wget -q \
    https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
    -O /tmp/cmdline-tools.zip \
    && unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools \
    && mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools/latest \
    && mv /tmp/cmdline-tools/cmdline-tools/* \
          ${ANDROID_SDK_ROOT}/cmdline-tools/latest/ \
    && rm -rf /tmp/cmdline-tools /tmp/cmdline-tools.zip

# Accept Android SDK licenses
RUN yes | sdkmanager --licenses >/dev/null || true

# Install ADB
RUN sdkmanager "platform-tools"

# Install Android Emulator
RUN sdkmanager "emulator"

# Verify ADB installation
RUN adb version

# Verify Android Emulator installation
RUN /opt/android-sdk/emulator/emulator -version

# Container startup script
COPY start.sh /app/start.sh

RUN chmod +x /app/start.sh

ENTRYPOINT ["/app/start.sh"]
