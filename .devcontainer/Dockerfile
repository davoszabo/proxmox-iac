FROM mcr.microsoft.com/devcontainers/python:3.12-bookworm

# Install Ansible essentials and dev tools
ARG ANSIBLE_VERSION="12.0.0"
RUN pip install ansible==${ANSIBLE_VERSION}

ARG ANSIBLE_DEV_TOOLS_VERSION="25.8.3"
RUN pip install ansible-dev-tools==${ANSIBLE_DEV_TOOLS_VERSION}

# Install OpenTofu (Terraform)
RUN curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh \
    && chmod +x install-opentofu.sh \
    && ./install-opentofu.sh --install-method deb \
    && rm -f install-opentofu.sh

# Packer + QEMU: bake qemu-guest-agent into the Debian cloud image (needs KVM on the host)
RUN apt-get update && apt-get install -y --no-install-recommends \
      qemu-system-x86 \
      qemu-utils \
      xorriso \
      ca-certificates \
      gnupg \
    && curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com bookworm main" \
         > /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update \
    && apt-get install -y packer \
    && rm -rf /var/lib/apt/lists/*

