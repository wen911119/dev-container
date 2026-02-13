# 1. Use a minimal base image
FROM debian:bullseye-slim

# Set environment variables to non-interactive to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# 2. Install system dependencies
# Install git, curl for downloading, and zsh for the shell.
# Clean up apt cache to keep the image small.
RUN apt-get update && apt-get install -y \
    curl \
    git \
    zsh \
    libatomic1 \
    ca-certificates \
    vim \
    nano \
    less \
    procps \
    sudo \
    locales \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2.0 Configure locales
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# 2.1 Configure git for cross-platform compatibility
# This prevents false positives when using Windows host with Linux container
RUN git config --global core.autocrlf false && \
    git config --global core.filemode false && \
    git config --global core.eol lf

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

# 5.1 Install Starship prompt (High performance, customizable prompt)
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y

# 5.2 Configure Starship
# Set Docker indicator to green, and git branch to yellow
RUN mkdir -p /etc/starship && \
    echo '[container]\nformat = "[$symbol $name]($style) "\nstyle = "green bold"\n\n[git_branch]\nstyle = "yellow bold"' > /etc/starship/starship.toml
ENV STARSHIP_CONFIG=/etc/starship/starship.toml

# 6. Make shell configurations globally effective
# Append sourcing of nvm and plugins to the global zshrc file.
# This ensures they are loaded for any user with zsh as their shell.
RUN echo '\n# Load nvm' >> /etc/zsh/zshrc && \
    echo 'export NVM_DIR="/usr/local/nvm"' >> /etc/zsh/zshrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /etc/zsh/zshrc && \
    echo '\n# Load zsh plugins' >> /etc/zsh/zshrc && \
    echo 'autoload -U compinit && compinit -u' >> /etc/zsh/zshrc && \
    echo 'alias ls="ls --color=auto"' >> /etc/zsh/zshrc && \
    echo 'export LS_COLORS="di=01;36:ln=01;36:so=01;35:pi=33:ex=01;32:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"' >> /etc/zsh/zshrc && \
    echo 'zstyle ":completion:*" list-colors "${(s.:.)LS_COLORS}"' >> /etc/zsh/zshrc && \
    echo 'alias ll="ls -lh"' >> /etc/zsh/zshrc && \
    echo 'alias la="ls -lha"' >> /etc/zsh/zshrc && \
    echo '\n# Git Aliases' >> /etc/zsh/zshrc && \
    echo 'alias g="git"' >> /etc/zsh/zshrc && \
    echo 'alias ga="git add"' >> /etc/zsh/zshrc && \
    echo 'alias gaa="git add --all"' >> /etc/zsh/zshrc && \
    echo 'alias gc="git commit"' >> /etc/zsh/zshrc && \
    echo 'alias gcm="git commit -m"' >> /etc/zsh/zshrc && \
    echo 'alias gs="git status"' >> /etc/zsh/zshrc && \
    echo 'alias gp="git push"' >> /etc/zsh/zshrc && \
    echo 'alias gl="git pull"' >> /etc/zsh/zshrc && \
    echo 'alias gco="git checkout"' >> /etc/zsh/zshrc && \
    echo '\n# Navigation & Utils' >> /etc/zsh/zshrc && \
    echo 'alias ..="cd .."' >> /etc/zsh/zshrc && \
    echo 'alias ...="cd ../.."' >> /etc/zsh/zshrc && \
    echo 'alias grep="grep --color=auto"' >> /etc/zsh/zshrc && \
    echo '\n# History Config' >> /etc/zsh/zshrc && \
    echo 'HISTSIZE=10000' >> /etc/zsh/zshrc && \
    echo 'SAVEHIST=10000' >> /etc/zsh/zshrc && \
    echo 'setopt HIST_IGNORE_DUPS' >> /etc/zsh/zshrc && \
    echo 'setopt SHARE_HISTORY' >> /etc/zsh/zshrc && \
    echo '\n# Initialize Starship prompt' >> /etc/zsh/zshrc && \
    echo 'eval "$(starship init zsh)"' >> /etc/zsh/zshrc && \
    echo 'source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh' >> /etc/zsh/zshrc && \
    echo 'source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> /etc/zsh/zshrc

# 7. Create a non-root user for devcontainer best practices
# This avoids permission issues and follows security best practices
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m -s /bin/zsh $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && chown -R $USERNAME:$USERNAME $NVM_DIR

# 8. Set zsh as the default shell for the user
RUN chsh -s /bin/zsh $USERNAME

# 9. Set working directory (Use home directory to play nice with VS Code default attach behavior)
WORKDIR /home/$USERNAME

# 10. Switch to non-root user
USER $USERNAME

# 11. Clone project code (Configured via Build Arguments & Secrets)
ARG REPO_URL
ARG REPO_BRANCH
ARG PROJECT_NAME

# Logic:
# 1. If git_token secret exists, use it to construct authenticated URL
# 2. Otherwise, try public clone
# 3. Handle cases where REPO_URL is missing
RUN --mount=type=secret,id=git_token,uid=1000 \
    if [ -n "$REPO_URL" ] && echo "$REPO_URL" | grep -q "^https://"; then \
        # Remove 'https://' prefix for token injection
        CLEAN_URL=${REPO_URL#https://}; \
        if [ -f /run/secrets/git_token ]; then \
            echo "🔐 Detected git_token secret, using authenticated clone..."; \
            TOKEN=$(cat /run/secrets/git_token); \
            git clone -b "$REPO_BRANCH" "https://${TOKEN}@${CLEAN_URL}" "$PROJECT_NAME"; \
        else \
            echo "🌍 No git_token secret found, trying public clone..."; \
            if ! OUTPUT=$(git clone -b "$REPO_BRANCH" "$REPO_URL" "$PROJECT_NAME" 2>&1); then \
                echo "$OUTPUT"; \
                echo "❌ ---------------------------------------------------"; \
                if echo "$OUTPUT" | grep -qE "Authentication failed|Repository not found|could not read Username"; then \
                    echo "❌ Authentication Failed / Repository Not Found"; \
                    echo "❌ If this is a PRIVATE repository, you MUST provide an Access Token."; \
                    echo "❌ Please check README.md and configure fe/.git_token file."; \
                elif echo "$OUTPUT" | grep -q "Remote branch"; then \
                    echo "❌ Remote Branch '$REPO_BRANCH' Not Found"; \
                    echo "❌ Please check 'repo_branch' in fe/project.json."; \
                else \
                    echo "❌ Git Clone Failed (Unknown Error)"; \
                    echo "❌ Please check your network connection or repo_url."; \
                fi; \
                echo "❌ ---------------------------------------------------"; \
                exit 1; \
            fi; \
        fi \
    else \
        echo "⚠️  Skipping code clone: repo_url is missing or not HTTPS."; \
    fi

# 12. Set working directory to the cloned project
WORKDIR /home/$USERNAME/$PROJECT_NAME

# 13. Auto-navigate to project directory when shell starts
# If we are in HOME, cd to project directory automatically
# This is a workaround for VS Code "Attach to Running Container" defaulting to /home/vscode
# Note: We only add this if we are not already in the project directory
RUN echo "if [ \"\$PWD\" = \"\$HOME\" ] && [ -d \"/home/$USERNAME/$PROJECT_NAME\" ]; then cd /home/$USERNAME/$PROJECT_NAME; fi" >> /home/$USERNAME/.zshrc

# Set a command that runs indefinitely to keep the container alive.
# This makes it friendly for GUI tools like Docker Desktop.
# You can get a shell by using the 'Exec' or 'Terminal' tab for the running container.
CMD ["tail", "-f", "/dev/null"]
