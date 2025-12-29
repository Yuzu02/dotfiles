{ config, pkgs, lib, ... }:

{
  # ============================================================================
  # HOME MANAGER MINIMAL CONFIGURATION (2025/2026 - FIXED)
  # Lightweight setup for quick deploys, containers, and CI environments
  # ============================================================================

  home = {
    username = lib.mkDefault "yuzu";
    homeDirectory = lib.mkDefault "/home/yuzu";
    stateVersion = "24.11";

    packages = with pkgs; [
      # ── Essential CLI Tools ─────────────────────────────────────────────────
      eza                 # ls replacement
      bat                 # cat replacement
      ripgrep             # grep replacement
      fd                  # find replacement
      fzf                 # fuzzy finder
      zoxide              # cd replacement
      
      # ── Editor ──────────────────────────────────────────────────────────────
      neovim
      
      # ── Shell Tools ─────────────────────────────────────────────────────────
      starship            # Prompt
      atuin               # History
      zsh                 # Shell
      
      # ── Utilities ───────────────────────────────────────────────────────────
      jq                  # JSON processor
      git                 # Version control
    ];

    # Minimal aliases
    shellAliases = {
      ls = "eza --icons";
      ll = "eza -la --icons";
      cat = "bat";
      grep = "rg";
      find = "fd";
    };

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  programs = {
    home-manager.enable = true;
    
    # Minimal Zsh setup
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
    };
    
    # Prompt
    starship = {
      enable = true;
      enableZshIntegration = true;
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
    };
    
    # Git (minimal config)
    git = {
      enable = true;
      # FIXED: Use settings instead of extraConfig
      settings = {
        init.defaultBranch = "main";
      };
    };
  };

  # XDG directories
  xdg.enable = true;
}