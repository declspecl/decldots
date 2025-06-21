# Use Ubuntu as base image to simulate a typical Linux environment
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    zsh \
    vim \
    sudo \
    software-properties-common \
    ca-certificates \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Install Ruby using rbenv for a more realistic setup
RUN git clone https://github.com/rbenv/rbenv.git /root/.rbenv && \
    echo 'export PATH="/root/.rbenv/bin:$PATH"' >> /root/.bashrc && \
    echo 'eval "$(rbenv init -)"' >> /root/.bashrc && \
    git clone https://github.com/rbenv/ruby-build.git /root/.rbenv/plugins/ruby-build

# Install specific Ruby version
ENV PATH="/root/.rbenv/bin:/root/.rbenv/shims:$PATH"
RUN rbenv install 3.1.0 && \
    rbenv global 3.1.0 && \
    rbenv rehash

# Install Homebrew for Linux (for testing package management)
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /root/.bashrc

# Set up the environment
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"

# Create a test user for more realistic testing
RUN useradd -m -s /bin/zsh testuser && \
    echo 'testuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Switch to test user
USER testuser
WORKDIR /home/testuser

# Set up Ruby environment for test user
RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv && \
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc && \
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc && \
    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

ENV PATH="/home/testuser/.rbenv/bin:/home/testuser/.rbenv/shims:$PATH"
RUN ~/.rbenv/bin/rbenv install 3.1.0 && \
    ~/.rbenv/bin/rbenv global 3.1.0 && \
    ~/.rbenv/bin/rbenv rehash

# Install Homebrew for the test user
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc

# Set up environment for Homebrew
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"

# Create directories that Decldots expects
RUN mkdir -p ~/.decldots/dotfiles ~/.config

# Copy the Decldots project
COPY --chown=testuser:testuser . /home/testuser/decldots

# Set working directory to the project
WORKDIR /home/testuser/decldots

# Install Ruby dependencies
RUN ~/.rbenv/shims/gem install bundler && \
    ~/.rbenv/shims/bundle install

# Create some example dotfiles for testing
RUN mkdir -p ~/.decldots/dotfiles/nvim ~/.decldots/dotfiles/emacs && \
    echo '# Example nvim configuration' > ~/.decldots/dotfiles/nvim/init.vim && \
    echo '; Example emacs configuration' > ~/.decldots/dotfiles/emacs/init.el && \
    echo '# Example hypr configuration' > ~/.decldots/dotfiles/hypr && \
    echo '# Example kitty configuration' > ~/.decldots/dotfiles/kitty

# Make the binary executable
RUN chmod +x bin/decldots

# Set up shell
RUN echo 'export PATH="/home/testuser/decldots/bin:$PATH"' >> ~/.bashrc && \
    echo 'export PATH="/home/testuser/decldots/bin:$PATH"' >> ~/.zshrc

# Default command
CMD ["/bin/bash", "-l"] 