{ config, pkgs, ... }:

{
  # ============================================================================
  # HOME MANAGER MINIMAL CONFIGURATION
  # Lightweight setup for quick deploys
  # ============================================================================

  home = {
    username = "yuzu";
    homeDirectory = "/home/yuzu";
    stateVersion = "24.05";

    packages = with pkgs; [
      # Essentials only
      eza
      bat
      ripgrep
      fd
      fzf
      zoxide
      neovim
      starship
      atuin
    ];
  };

  programs = {
    home-manager.enable = true;
    
    starship.enable = true;
    
    atuin = {
      enable = true;
      enableZshIntegration = true;
    };
    
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
    
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
