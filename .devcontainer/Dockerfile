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

