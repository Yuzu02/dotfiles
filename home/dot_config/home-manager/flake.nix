{
  description = "Yuzu's Home Manager configuration (2025/2026 Best Practices)";

  inputs = {
    # Core inputs - pinned to unstable for latest packages
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    # Home Manager - follows nixpkgs for consistency
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Catppuccin theming for Nix
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Nix index database for command-not-found
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Flake utilities
    flake-utils.url = "github:numtide/flake-utils";
    
    # NixGL for OpenGL on non-NixOS
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, catppuccin, nix-index-database, flake-utils, nixgl, ... }@inputs:
    let
      # Supported systems
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      
      # Helper function to generate outputs for each system
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      
      # System-specific package sets
      pkgsFor = system: import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          # Enable experimental features
          experimental-features = [ "nix-command" "flakes" ];
        };
        overlays = [
          nixgl.overlay
        ];
      };
      
      # Common Home Manager modules
      commonModules = [
        catppuccin.homeManagerModules.catppuccin
        nix-index-database.hmModules.nix-index
      ];
      
      # User configuration helper
      mkHomeConfiguration = { system ? "x86_64-linux", username, configFile, extraModules ? [] }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor system;
          modules = commonModules ++ [
            configFile
          ] ++ extraModules;
          extraSpecialArgs = {
            inherit inputs;
            inherit nixgl;
          };
        };
        
    in {
      # Home configurations for different users/machines
      homeConfigurations = {
        # Full configuration
        "yuzu" = mkHomeConfiguration {
          username = "yuzu";
          configFile = ./home.nix;
        };
        
        # Minimal configuration for quick deploys
        "yuzu-minimal" = mkHomeConfiguration {
          username = "yuzu";
          configFile = ./home-minimal.nix;
        };
        
        # Generic user configuration (uses $USER at build time)
        "default" = mkHomeConfiguration {
          username = "user";
          configFile = ./home.nix;
        };
        
        # Container/CI optimized
        "ci" = mkHomeConfiguration {
          username = "runner";
          configFile = ./home-minimal.nix;
        };
      };
      
      # Development shells for each system
      devShells = forAllSystems (system: 
        let pkgs = pkgsFor system; in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              # Nix tools
              nil
              nixfmt-rfc-style
              nix-output-monitor
              nvd
              
              # Development
              git
              chezmoi
            ];
            
            shellHook = ''
              echo "🏠 Home Manager Development Shell"
              echo "Commands:"
              echo "  home-manager switch --flake .     # Apply configuration"
              echo "  nix flake check                   # Validate flake"
              echo "  nix flake update                  # Update inputs"
            '';
          };
        }
      );
      
      # Formatter for nix files
      formatter = forAllSystems (system: (pkgsFor system).nixfmt-rfc-style);
    };
}
