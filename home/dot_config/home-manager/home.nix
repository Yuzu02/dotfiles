{ config, pkgs, ... }:

{
  # ============================================================================
  # HOME MANAGER CONFIGURATION
  # Full featured setup with Catppuccin theming
  # ============================================================================

  home = {
    username = "yuzu";
    homeDirectory = "/home/yuzu";
    stateVerYysion = "24.05";

    packages = with pkgs; [
      # Modern CLI tools
      eza
      bat
      ripgrep
      fd
      fzf
      zoxide
      dust
      duf
      procs
      
      # Git tools
      delta
      lazygit
      gh
      
      # Development
      neovim
      
      # System
      btop
      fastfetch
      
      # Terminal
      zellij
      starship
      atuin
      direnv
      
      # File management
      yazi
      
      # Nix tools
      nil
      nixfmt-rfc-style
    ];
  };

  # Enable Catppuccin Mocha theme
  catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "mauve";
  };

  # Programs managed by Home Manager
  programs = {
    home-manager.enable = true;
    
    # Shell
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
    };
    
    # Git
    git = {
      enable = true;
      delta.enable = true;
    };
    
    # Prompt
    starship = {
      enable = true;
      catppuccin.enable = true;
    };
    
    # History
    atuin = {
      enable = true;
      enableZshIntegration = true;
    };
    
    # Navigation
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
    
    # Fuzzy finder
    fzf = {
      enable = true;
      enableZshIntegration = true;
      catppuccin.enable = true;
    };
    
    # File viewer
    bat = {
      enable = true;
      catppuccin.enable = true;
    };
    
    # System monitor
    btop = {
      enable = true;
      catppuccin.enable = true;
    };
    
    # Direnv
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
    
    # Nix index for command-not-found
    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };
  };
  
  # XDG directories
  xdg.enable = true;
}
