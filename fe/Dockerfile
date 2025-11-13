# 1. Use a minimal base image
FROM debian:bullseye-slim

# Set environment variables to non-interactive to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# 2. Install system dependencies
# Install git, curl for downloading, and zsh for the shell.
# Clean up apt cache to keep the image small.
RUN apt-get update && apt-get install -y \
    curl \
    git \
    zsh \
    libatomic1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. Install nvm
# This is placed before Node.js installation to leverage layer caching.
ENV NVM_DIR=/usr/local/nvm
RUN mkdir -p $NVM_DIR && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

# 4. Install Node.js, yarn, and pnpm using nvm
# Sourcing nvm.sh makes the nvm command available.
# Using an environment variable for the Node.js version makes it easy to update.
RUN . "$NVM_DIR/nvm.sh" && nvm install --lts && nvm alias default 'lts/*' && nvm use default && corepack enable

# 5. Configure shell enhancements globally
# Clone plugins to a shared location.
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /usr/local/share/zsh-syntax-highlighting && \
    git clone https://github.com/zsh-users/zsh-autosuggestions.git /usr/local/share/zsh-autosuggestions

# 6. Make shell configurations globally effective
# Append sourcing of nvm and plugins to the global zshrc file.
# This ensures they are loaded for any user with zsh as their shell.
RUN echo '\n# Load nvm' >> /etc/zsh/zshrc && \
    echo 'export NVM_DIR="/usr/local/nvm"' >> /etc/zsh/zshrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /etc/zsh/zshrc && \
    echo '\n# Load zsh plugins' >> /etc/zsh/zshrc && \
    echo 'source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> /etc/zsh/zshrc && \
    echo 'source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh' >> /etc/zsh/zshrc

# 7. Set zsh as the default shell
# This is more robust than using CMD ["zsh"].
RUN chsh -s /bin/zsh

# Set a command that runs indefinitely to keep the container alive.
# This makes it friendly for GUI tools like Docker Desktop.
# You can get a shell by using the 'Exec' or 'Terminal' tab for the running container.
CMD ["tail", "-f", "/dev/null"]
