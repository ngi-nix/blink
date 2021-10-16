{
  description = "";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self , nixpkgs }:
    let

      # Generate a user-friendly version numer
      version = "${builtins.substring 0 8 self.lastModifiedDate}-${self.shortRev or "dirty"}";

      # System types to support
      supportedSystems = [ "x86_64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types with package overlaid
      nixpkgsBySystem = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            python3 = prev.python3.override {
              packageOverrides = final': prev': {
                python3-msrplib = final'.callPackage ./python3-msrplib.nix {};
                python3-otr = final'.callPackage ./python3-otr.nix {};
                python3-sipsimple = final'.callPackage ./python3-sipsimple.nix {};
                python3-xcaplib = final'.callPackage ./python3-xcaplib.nix {};
              };
            };
          })
          self.overlay
        ];
      });

      forAttrs = attrs: f: nixpkgs.lib.mapAttrs f attrs;

    in {

      # A Nixpkgs overlay that adds the package
      overlay = final: prev: {
        blink = final.libsForQt5.callPackage ./blink.nix {};
        sipclients3 = final.callPackage ./sipclients3.nix {};
      };

      # The package built against the specified Nixpkgs version
      packages = forAttrs nixpkgsBySystem (_: pkgs: {
        inherit (pkgs) blink sipclients3;
      });

      # The default package for 'nix build'
      defaultPackage = forAttrs self.packages (_: pkgs: pkgs.blink);
    };
}
