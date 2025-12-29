{ config, pkgs, lib, inputs, ... }:

{
  # ============================================================================
  # HOME MANAGER CONFIGURATION (2025/2026 Best Practices)
  # Full featured setup with Catppuccin theming and modern CLI tools
  # Integrates with Chezmoi for hybrid dotfile management
  # ============================================================================

  home = {
    username = "yuzu";
    homeDirectory = "/home/yuzu";
    stateVersion = "24.11"; # Updated to latest stable

    # =========================================================================
    # PACKAGES - Modern CLI Tools
    # =========================================================================
    packages = with pkgs; [
      # ── Core CLI Replacements ──────────────────────────────────────────────
      eza                 # ls replacement with icons
      bat                 # cat replacement with syntax highlighting
      ripgrep             # grep replacement (rg)
      fd                  # find replacement
      fzf                 # fuzzy finder
      zoxide              # cd replacement with frecency
      dust                # du replacement with visualization
      duf                 # df replacement
      procs               # ps replacement
      sd                  # sed replacement
      choose              # cut replacement
      jq                  # JSON processor
      yq                  # YAML processor
      
      # ── Git Tools ──────────────────────────────────────────────────────────
      delta               # Git diff viewer
      lazygit             # Git TUI
      gh                  # GitHub CLI
      gitu                # Git TUI (alternative)
      
      # ── Development ────────────────────────────────────────────────────────
      neovim              # Modal editor
      helix               # Modern modal editor
      
      # ── System Monitoring ──────────────────────────────────────────────────
      btop                # System monitor
      bottom              # Another system monitor (btm)
      bandwhich           # Network utilization
      
      # ── Terminal & Shell ───────────────────────────────────────────────────
      zellij              # Terminal multiplexer
      starship            # Cross-shell prompt
      atuin               # Shell history sync
      direnv              # Auto-load environments
      carapace            # Universal completions
      
      # ── File Management ────────────────────────────────────────────────────
      yazi                # Terminal file manager
      broot               # Tree navigation
      
      # ── Nix Tools ──────────────────────────────────────────────────────────
      nil                 # Nix LSP
      nixfmt-rfc-style    # Nix formatter
      nix-output-monitor  # Pretty nix build output
      nvd                 # Nix version diff
      nix-tree            # Dependency tree viewer
      
      # ── Utilities ──────────────────────────────────────────────────────────
      fastfetch           # System info display
      httpie              # HTTP client
      hyperfine           # Benchmarking
      tokei               # Code statistics
      tealdeer            # tldr client
      
      # ── Archive & Compression ──────────────────────────────────────────────
      ouch                # Universal archive tool
      
      # ── Security ───────────────────────────────────────────────────────────
      age                 # Modern encryption
    ];

    # =========================================================================
    # SESSION VARIABLES
    # =========================================================================
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "less -R";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      
      # XDG Base Directory
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";
      XDG_CACHE_HOME = "$HOME/.cache";
      
      # Tool-specific
      BAT_THEME = "Catppuccin Mocha";
      FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8";
    };

    # =========================================================================
    # SHELL ALIASES
    # =========================================================================
    shellAliases = {
      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      
      # Modern replacements
      ls = "eza --icons --group-directories-first";
      ll = "eza -la --icons --group-directories-first";
      lt = "eza --tree --icons --level=2";
      la = "eza -a --icons";
      
      cat = "bat";
      grep = "rg";
      find = "fd";
      du = "dust";
      df = "duf";
      ps = "procs";
      sed = "sd";
      top = "btop";
      
      # Git
      g = "git";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph";
      lg = "lazygit";
      
      # Nix
      nrs = "sudo nixos-rebuild switch";
      hms = "home-manager switch --flake ~/.config/home-manager";
      nfu = "nix flake update";
      
      # Chezmoi
      cz = "chezmoi";
      cza = "chezmoi apply";
      czd = "chezmoi diff";
      cze = "chezmoi edit";
      czu = "chezmoi update";
      
      # System
      reload = "exec $SHELL";
      path = "echo $PATH | tr ':' '\n'";
    };
  };

  # ===========================================================================
  # CATPPUCCIN THEMING
  # ===========================================================================
  catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "mauve";
  };

  # ===========================================================================
  # PROGRAMS CONFIGURATION
  # ===========================================================================
  programs = {
    # Enable Home Manager self-management
    home-manager.enable = true;
    
    # ── Shell ────────────────────────────────────────────────────────────────
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      enableCompletion = true;
      
      history = {
        size = 50000;
        save = 50000;
        ignoreDups = true;
        ignoreSpace = true;
        extended = true;
        share = true;
      };
      
      initExtra = ''
        # Load Catppuccin colors
        export LS_COLORS="$(vivid generate catppuccin-mocha 2>/dev/null || echo "")"
        
        # Keybindings
        bindkey '^[[A' history-search-backward
        bindkey '^[[B' history-search-forward
        bindkey '^[[H' beginning-of-line
        bindkey '^[[F' end-of-line
        
        # Integration with chezmoi-managed configs
        [ -f ~/.config/zsh/local.zsh ] && source ~/.config/zsh/local.zsh
      '';
    };
    
    # ── Git ──────────────────────────────────────────────────────────────────
    git = {
      enable = true;
      delta = {
        enable = true;
        options = {
          navigate = true;
          side-by-side = true;
          line-numbers = true;
        };
      };
      
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        core.autocrlf = "input";
        merge.conflictstyle = "diff3";
        diff.colorMoved = "default";
        rerere.enabled = true;
      };
    };
    
    # ── Prompt ───────────────────────────────────────────────────────────────
    starship = {
      enable = true;
      catppuccin.enable = true;
      enableZshIntegration = true;
    };
    
    # ── History ──────────────────────────────────────────────────────────────
    atuin = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        auto_sync = true;
        sync_frequency = "5m";
        search_mode = "fuzzy";
        filter_mode = "global";
        style = "compact";
      };
    };
    
    # ── Navigation ───────────────────────────────────────────────────────────
    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [ "--cmd cd" ];
    };
    
    # ── Fuzzy Finder ─────────────────────────────────────────────────────────
    fzf = {
      enable = true;
      enableZshIntegration = true;
      catppuccin.enable = true;
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
        "--preview 'bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || eza -la --icons {}'"
      ];
    };
    
    # ── File Viewer ──────────────────────────────────────────────────────────
    bat = {
      enable = true;
      catppuccin.enable = true;
      config = {
        style = "numbers,changes,header";
        italic-text = "always";
      };
    };
    
    # ── System Monitor ───────────────────────────────────────────────────────
    btop = {
      enable = true;
      catppuccin.enable = true;
    };
    
    # ── Environment ──────────────────────────────────────────────────────────
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
      config = {
        global = {
          warn_timeout = "30s";
          hide_env_diff = true;
        };
      };
    };
    
    # ── Command Not Found ────────────────────────────────────────────────────
    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };
    
    # ── Terminal Multiplexer ─────────────────────────────────────────────────
    zellij = {
      enable = true;
      catppuccin.enable = true;
    };
    
    # ── File Manager ─────────────────────────────────────────────────────────
    yazi = {
      enable = true;
      catppuccin.enable = true;
      enableZshIntegration = true;
    };
    
    # ── Completions ──────────────────────────────────────────────────────────
    carapace = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  # ===========================================================================
  # XDG DIRECTORIES
  # ===========================================================================
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  # ===========================================================================
  # SYSTEM INTEGRATION
  # ===========================================================================
  
  # Manage fonts
  fonts.fontconfig.enable = true;

  # Targets for specific platforms
  targets.genericLinux.enable = true;
}
