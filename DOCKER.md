# Docker Testing Environment

This directory includes a complete Docker environment for safely testing Decldots without affecting your host system.

## Quick Start

### 1. Build and Run the Container

```bash
# Build and start the container
docker-compose up --build -d

# Enter the interactive shell
docker-compose exec decldots-test /bin/bash
```

### 2. Test Decldots

Once inside the container:

```bash
# Run the Docker-specific test configuration
ruby scripts/docker-test.rb

# Or use the CLI commands
bundle exec decldots example
bundle exec decldots diff
bundle exec decldots apply
```

## Available Test Scenarios

### Basic Testing

```bash
# Test the example configuration
bundle exec decldots example

# See what changes would be made
bundle exec decldots diff

# Apply configuration in dry-run mode (safe)
bundle exec decldots apply
```

### Advanced Testing

```bash
# Run comprehensive Docker tests
ruby scripts/docker-test.rb

# Test package management (Homebrew)
brew --version  # Should be available

# Test shell configuration
zsh  # Switch to zsh shell
exit  # Return to bash

# Verify dotfiles creation
ls -la ~/.config/
ls -la ~/.decldots/
```

## Container Features

### Pre-installed Software
- **Ubuntu 22.04** base system
- **Ruby 3.1.0** via rbenv
- **Homebrew** for Linux package management
- **Zsh** shell
- **Git** for version control
- **Build tools** for compiling packages

### Test User Setup
- Non-root user `testuser` with sudo access
- Clean home directory for realistic testing
- Proper shell environment configuration
- Decldots CLI available in PATH

### Safety Features
- **Dry-run mode** enabled by default via environment variable
- **Isolated filesystem** - no access to host files
- **Temporary directories** for all operations
- **Easy cleanup** via container restart

## Dockerfile Details

The Docker environment provides:

1. **Realistic Linux environment** mimicking a typical dotfile setup
2. **Complete Ruby toolchain** with proper version management
3. **Package manager support** for testing installations
4. **User permissions** that match real-world usage
5. **Pre-configured directories** that Decldots expects

## Development Workflow

### Live Code Changes

The docker-compose setup mounts your local project directory into the container, so you can:

1. Edit code on your host machine
2. Test changes immediately in the container
3. No need to rebuild for code changes

```bash
# Make changes to lib/decldots/*.rb on your host
# Then in the container:
bundle exec decldots apply  # Tests your changes immediately
```

### Container Management

```bash
# Start the container
docker-compose up -d

# Enter the container
docker-compose exec decldots-test /bin/bash

# View logs
docker-compose logs decldots-test

# Stop the container
docker-compose down

# Rebuild after Dockerfile changes
docker-compose up --build -d

# Remove everything (clean slate)
docker-compose down -v
docker system prune
```

## Testing Scenarios

### Package Installation
```bash
# The Docker environment includes Homebrew
brew install neovim  # Should work in container
```

### Dotfile Creation
```bash
# Test both symlink and copy operations
ls -la ~/.config/nvim/     # Should show symlink (mutable)
ls -la ~/.config/emacs/    # Should show copied files (immutable)
```

### Shell Configuration
```bash
# Test generated shell configuration
cat ~/.zshrc  # Should show generated Oh My Zsh setup
source ~/.zshrc  # Should load without errors
```

### Git Configuration
```bash
# Test generated git configuration
cat ~/.gitconfig  # Should show generated git settings
git config --list  # Should display all settings
```

## Troubleshooting

### Container Won't Start
```bash
# Check for port conflicts or permission issues
docker-compose logs decldots-test

# Clean rebuild
docker-compose down -v
docker-compose up --build
```

### Ruby/Bundler Issues
```bash
# Inside container, check Ruby setup
which ruby
ruby --version
bundle --version

# Reinstall dependencies if needed
bundle install
```

### Homebrew Issues
```bash
# Check Homebrew installation
brew --version
brew doctor

# Ensure proper environment
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

## Security Notes

- Container runs as non-root user for realistic testing
- No network access to sensitive services
- Isolated from host filesystem (except mounted project directory)
- All package installations are contained within the container
- Easy to reset by destroying and recreating the container

This Docker environment provides a completely safe sandbox for testing Decldots functionality without any risk to your host system! 