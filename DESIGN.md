# Rbdots Design Document

## Overview

Rbdots is a declarative dotfile management framework that provides the flexibility of Nix's declarative configuration model without its immutable constraints. Built with Ruby, it offers a composable, extensible architecture that supports multiple package managers and configuration targets.

## Core Philosophy

- **Declarative**: Users describe what they want, not how to achieve it
- **Extensible**: New package managers and programs can be added through adapters
- **Mutable**: Unlike Nix, allows for mutable configurations where needed
- **Type-Safe**: Leverages Ruby's dynamic nature while maintaining configuration validation
- **Composable**: Configurations can be split, shared, and combined

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    User Configuration                       │
│                     (Ruby DSL)                             │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                 Configuration Parser                        │
│              (DSL → Internal Representation)               │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                Configuration Engine                         │
│            (Orchestrates application of config)            │
└─────────┬───────────────────────────────┬───────────────────┘
          │                               │
┌─────────▼─────────┐           ┌─────────▼─────────┐
│  Package Managers │           │   Program Configs │
│     (Adapters)    │           │     (Handlers)    │
│                   │           │                   │
│ • HomeBrew        │           │ • Shell (zsh/bash)│
│ • APT/DNF         │           │ • Git             │
│ • Pacman          │           │ • VSCode          │
│ • Nix             │           │ • Dotfiles        │
│ • Cargo           │           │ • GTK/Themes      │
└───────────────────┘           └───────────────────┘
```

## Core Components

### 1. Configuration DSL

The Ruby DSL provides an intuitive interface for declaring system configuration:

```ruby
Rbdots.configure do |config|
  # Package management
  config.packages.homebrew do
    install "git", "curl", "nodejs"
    cask "firefox", "vscode"
  end
  
  # Program configurations
  config.programs.zsh do
    enable_completion true
    enable_autosuggestion true
    
    aliases do
      ls "eza"
      cls "clear"
    end
    
    shell_init <<~SHELL
      setopt ignore_eof
      PROMPT=' %{$fg[magenta]%}%0*%{$reset_color%} '
    SHELL
  end
  
  # Dotfiles management
  config.dotfiles do
    link "emacs", mutable: true
    link "hypr", mutable: false
    link "kitty", mutable: false
  end
  
  # System theming
  config.system.gtk do
    theme "gruvbox-dark"
    icon_theme "oomox-gruvbox-dark"
    cursor_theme "Bibata-Modern-Ice", size: 20
  end
end
```

### 2. Configuration Engine

**Core Class: `Rbdots::Engine`**

Responsibilities:
- Parse and validate user configuration
- Orchestrate execution across adapters and handlers
- Manage state and rollback capabilities
- Handle dependency resolution between components

**Key Methods:**
```ruby
class Rbdots::Engine
  def apply_configuration(config)
    # Parse and validate configuration
    # Resolve dependencies
    # Execute in correct order
    # Handle rollback on failure
  end
  
  def diff_configuration(config)
    # Show what would change without applying
  end
  
  def rollback_to(checkpoint)
    # Rollback to previous state
  end
end
```

### 3. Package Manager Adapters

**Base Class: `Rbdots::Adapters::PackageManager`**

Each package manager has its own adapter that implements a common interface:

```ruby
module Rbdots::Adapters
  class PackageManager
    def install(packages)
      raise NotImplementedError
    end
    
    def uninstall(packages)
      raise NotImplementedError
    end
    
    def update(packages = nil)
      raise NotImplementedError
    end
    
    def installed?(package)
      raise NotImplementedError
    end
  end
  
  class Homebrew < PackageManager
    # Implementation for brew commands
  end
  
  class Apt < PackageManager
    # Implementation for apt commands
  end
end
```

### 4. Program Configuration Handlers

**Base Class: `Rbdots::Handlers::Program`**

Each program type has a handler that knows how to configure it:

```ruby
module Rbdots::Handlers
  class Program
    def configure(options)
      raise NotImplementedError
    end
    
    def validate_options(options)
      raise NotImplementedError
    end
  end
  
  class Shell < Program
    def configure(options)
      # Generate shell configuration files
      # Handle aliases, environment variables, etc.
    end
  end
  
  class Git < Program
    def configure(options)
      # Generate .gitconfig
      # Set up credentials, aliases, etc.
    end
  end
end
```

### 5. Dotfiles Manager

**Class: `Rbdots::DotfilesManager`**

Handles symlinking and copying of configuration files:

```ruby
class Rbdots::DotfilesManager
  def link_config(name, options = {})
    if options[:mutable]
      create_mutable_link(name)
    else
      create_immutable_copy(name)
    end
  end
  
  private
  
  def create_mutable_link(name)
    # Create symlink to allow editing
  end
  
  def create_immutable_copy(name)
    # Copy file to prevent modification
  end
end
```

## Configuration State Management

### State Tracking
- **Current State**: Track what's currently installed/configured
- **Desired State**: What the configuration declares should exist
- **Diff Generation**: Compare current vs desired state
- **Rollback Points**: Create checkpoints before major changes

### State Storage
```ruby
# ~/.rbdots/state.json
{
  "packages": {
    "homebrew": ["git", "curl", "nodejs"],
    "npm": ["typescript", "eslint"]
  },
  "programs": {
    "zsh": { "last_configured": "2024-01-15T10:30:00Z" },
    "git": { "last_configured": "2024-01-15T10:30:00Z" }
  },
  "dotfiles": {
    "emacs": { "type": "mutable", "target": "~/.config/emacs" },
    "hypr": { "type": "immutable", "target": "~/.config/hypr" }
  }
}
```

## Extensibility Framework

### Adding New Package Managers

```ruby
# lib/rbdots/adapters/custom_package_manager.rb
module Rbdots::Adapters
  class CustomPackageManager < PackageManager
    def install(packages)
      # Implementation
    end
    
    # ... other required methods
  end
end

# Register the adapter
Rbdots.register_adapter(:custom_pm, Rbdots::Adapters::CustomPackageManager)
```

### Adding New Program Handlers

```ruby
# lib/rbdots/handlers/custom_program.rb
module Rbdots::Handlers
  class CustomProgram < Program
    def configure(options)
      # Generate config files for this program
    end
    
    def validate_options(options)
      # Validate the provided configuration options
    end
  end
end

# Register the handler
Rbdots.register_handler(:custom_program, Rbdots::Handlers::CustomProgram)
```

## Configuration Schema Validation

Use Ruby's type system and custom validation to ensure configuration correctness:

```ruby
module Rbdots::Schema
  class ConfigurationValidator
    def validate_packages(config)
      # Ensure package names are valid
      # Check for conflicts between different package managers
    end
    
    def validate_programs(config)
      # Validate program-specific options
      # Check for required dependencies
    end
  end
end
```

## File Structure

```
rbdots/
├── lib/
│   ├── rbdots/
│   │   ├── adapters/          # Package manager adapters
│   │   │   ├── homebrew.rb
│   │   │   ├── apt.rb
│   │   │   └── base.rb
│   │   ├── handlers/          # Program configuration handlers
│   │   │   ├── shell.rb
│   │   │   ├── git.rb
│   │   │   ├── vscode.rb
│   │   │   └── base.rb
│   │   ├── dsl/              # DSL components
│   │   │   ├── configuration.rb
│   │   │   ├── packages.rb
│   │   │   └── programs.rb
│   │   ├── engine.rb         # Main orchestration engine
│   │   ├── state_manager.rb  # State tracking and rollback
│   │   ├── dotfiles_manager.rb
│   │   └── validator.rb      # Configuration validation
│   └── rbdots.rb            # Main entry point
├── spec/                     # Test suite
├── examples/                 # Example configurations
└── README.md
```

## Implementation Phases

### Phase 1: Core Infrastructure
- Configuration DSL foundation
- Basic engine and state management
- Simple package manager adapter (homebrew)
- Basic dotfiles linking

### Phase 2: Program Configuration
- Shell configuration (zsh/bash)
- Git configuration
- Basic validation framework

### Phase 3: Advanced Features
- Multiple package manager support
- VSCode configuration
- GTK/theming support
- Rollback capabilities

### Phase 4: Ecosystem Expansion
- Community adapter/handler system
- Configuration sharing/templates
- Advanced validation and error handling

## Usage Example

```ruby
# ~/.rbdots/config.rb
Rbdots.configure do |config|
  config.user do
    name "dec"
    email "gavind2559@gmail.com"
    home_directory "/home/dec"
  end
  
  config.packages.homebrew do
    tap "homebrew/cask"
    install %w[
      clang cmake awscli lua-language-server
      firefox vscode spotify figma
    ]
  end
  
  config.programs.zsh do
    enable_completion true
    enable_autosuggestion true
    enable_syntax_highlighting true
    
    aliases do
      ls "eza"
      cls "clear"
      hmbs "rbdots apply"
    end
    
    oh_my_zsh do
      enable true
      theme "robbyrussell"
      plugins %w[git python man]
    end
  end
  
  config.programs.git do
    user_name "dec"
    user_email "gavind2559@gmail.com"
    default_branch "main"
    pull_rebase true
  end
  
  config.dotfiles do
    source_directory "~/.rbdots/dotfiles"
    
    link "emacs", mutable: true
    link "hypr", mutable: false
    link "kitty", mutable: false
  end
  
  config.system.gtk do
    theme "gruvbox-dark"
    icon_theme "oomox-gruvbox-dark"
    cursor_theme "Bibata-Modern-Ice", size: 20
  end
end
```

This design provides a solid foundation for building Rbdots as a powerful, extensible alternative to Nix home-manager while maintaining the declarative benefits you desire. 