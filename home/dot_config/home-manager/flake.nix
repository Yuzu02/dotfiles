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
      # Common Home Manager modules
      commonModules = [
        catppuccin.homeManagerModules.catppuccin
        nix-index-database.hmModules.nix-index
      ];
      
      # Helper function to create home configuration
      mkHomeConfiguration = { system, username, configFile }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ nixgl.overlay ];
          };
          
          modules = commonModules ++ [
            configFile
            {
              home = {
                username = username;
                homeDirectory = "/home/${username}";
                stateVersion = "24.11";
              };
            }
          ];
          
          extraSpecialArgs = {
            inherit inputs nixgl;
          };
        };
        
    in
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      {
        # Make homeConfigurations available per-system in legacyPackages
        # This fixes the "does not provide attribute" error
        legacyPackages = {
          homeConfigurations = {
            # Full configuration - use actual username or "root" for root user
            "root" = mkHomeConfiguration {
              inherit system;
              username = "root";
              configFile = ./home.nix;
            };
            
            # Minimal configuration
            "root-minimal" = mkHomeConfiguration {
              inherit system;
              username = "root";
              configFile = ./home-minimal.nix;
            };
            
            # Generic username configurations
            "yuzu" = mkHomeConfiguration {
              inherit system;
              username = "yuzu";
              configFile = ./home.nix;
            };
            
            "yuzu-minimal" = mkHomeConfiguration {
              inherit system;
              username = "yuzu";
              configFile = ./home-minimal.nix;
            };
            
            # Default fallback
            "default" = mkHomeConfiguration {
              inherit system;
              username = builtins.getEnv "USER";
              configFile = ./home.nix;
            };
          };
        };
      }
    ) // {
      # ALSO provide top-level homeConfigurations for compatibility
      # This allows both methods to work:
      # - nix build .#homeConfigurations.root.activationPackage
      # - nix build .#legacyPackages.x86_64-linux.homeConfigurations.root.activationPackage
      homeConfigurations = let
        system = "x86_64-linux";
      in {
        "root" = mkHomeConfiguration {
          inherit system;
          username = "root";
          configFile = ./home.nix;
        };
        
        "root-minimal" = mkHomeConfiguration {
          inherit system;
          username = "root";
          configFile = ./home-minimal.nix;
        };
        
        "yuzu" = mkHomeConfiguration {
          inherit system;
          username = "yuzu";
          configFile = ./home.nix;
        };
        
        "yuzu-minimal" = mkHomeConfiguration {
          inherit system;
          username = "yuzu";
          configFile = ./home-minimal.nix;
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