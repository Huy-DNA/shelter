{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShell = pkgs.mkShell {
        packages = with pkgs; [
          liberation_ttf
          nerd-fonts.jetbrains-mono 
          typst
          tinymist
          neovim
          docker
          nginx
          prometheus
          grafana
        ];
        CMAKE_EXPORT_COMPILE_COMMANDS = 1;
        shellHook = ''
          fc-cache -f -v >> /dev/null
        '';
      };
    });
}
