{
  description = "Fully featured, easy to use SIP client with a Qt based UI";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let

      # System types to support
      supportedSystems = [ "x86_64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types with package overlaid
      nixpkgsBySystem = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      });

      forAttrs = attrs: f: nixpkgs.lib.mapAttrs f attrs;

    in {

      # A Nixpkgs overlay that adds the packages
      overlay = final: prev: {
        blink = final.libsForQt5.callPackage ./blink.nix {};
        sipclients3 = final.callPackage ./sipclients3.nix {};
        python3 = prev.python3.override {
          packageOverrides = final': prev': {
            python3-msrplib = final'.callPackage ./deps/python3-msrplib.nix {};
            python3-otr = final'.callPackage ./deps/python3-otr.nix {};
            python3-sipsimple = final'.callPackage ./deps/python3-sipsimple.nix {};
            python3-xcaplib = final'.callPackage ./deps/python3-xcaplib.nix {};
          };
        };
      };

      # The package built against the specified Nixpkgs version
      packages = forAttrs nixpkgsBySystem (_: pkgs: {
        inherit (pkgs) blink sipclients3;
      });

      # The default package for 'nix build'
      defaultPackage = forAttrs self.packages (_: pkgs: pkgs.blink);
    };
}
