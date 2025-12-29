{
  description = "Yuzu's Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    catppuccin.url = "github:catppuccin/nix";
    
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, catppuccin, nix-index-database, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations."yuzu" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          catppuccin.homeManagerModules.catppuccin
          nix-index-database.hmModules.nix-index
          ./home.nix
        ];
      };
      
      # Minimal config for quick deploys
      homeConfigurations."yuzu-minimal" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home-minimal.nix
        ];
      };
    };
}
