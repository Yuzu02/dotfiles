{
  description = "Yuzu's Home Manager configuration (2025/2026 Best Practices - FIXED)";

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
  };

  outputs = { self, nixpkgs, home-manager, catppuccin, nix-index-database, flake-utils, ... }@inputs:
    let
      # Systems to support
      systems = [ "x86_64-linux" "aarch64-linux" ];
      
      # Helper function to create home configuration
      mkHomeConfiguration = { system, username }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          
          modules = [
            catppuccin.homeModules.catppuccin  # FIXED: Use homeModules instead of homeManagerModules
            nix-index-database.homeModules.nix-index  # FIXED: Use homeModules instead of hmModules
            ./home.nix
            {
              home = {
                username = username;
                homeDirectory = "/home/${username}";
                stateVersion = "24.11";
              };
            }
          ];
          
          extraSpecialArgs = {
            inherit inputs;
          };
        };
      
      # Helper for minimal config
      mkMinimalConfiguration = { system, username }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          
          modules = [
            ./home-minimal.nix
            {
              home = {
                username = username;
                homeDirectory = "/home/${username}";
                stateVersion = "24.11";
              };
            }
          ];
          
          extraSpecialArgs = {
            inherit inputs;
          };
        };
        
    in
    {
      # FIXED: Direct homeConfigurations without nested structure
      homeConfigurations = {
        # Full configurations
        "root" = mkHomeConfiguration {
          system = "x86_64-linux";
          username = "root";
        };
        
        "yuzu" = mkHomeConfiguration {
          system = "x86_64-linux";
          username = "yuzu";
        };
        
        # Minimal configurations
        "root-minimal" = mkMinimalConfiguration {
          system = "x86_64-linux";
          username = "root";
        };
        
        "yuzu-minimal" = mkMinimalConfiguration {
          system = "x86_64-linux";
          username = "yuzu";
        };
      };
      
      # Development shell
      devShells = flake-utils.lib.eachDefaultSystem (system: 
        let pkgs = nixpkgs.legacyPackages.${system}; in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nil
              nixfmt-rfc-style
              nix-output-monitor
              nvd
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
      
      # Formatter
      formatter = flake-utils.lib.eachDefaultSystem (system: 
        nixpkgs.legacyPackages.${system}.nixfmt-rfc-style
      );
    };
}