{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixpkgs-ruby = {
      url = "github:bobvanderlinden/nixpkgs-ruby";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-master, nixpkgs-ruby, emacs-overlay }:
    let
      system = "x86_64-linux";
      pkgs-master = import nixpkgs-master { inherit system; };
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          emacs-overlay.overlays.default
          # Disable folly tests - one test (AsyncSocketIntegrationTest.PingPongRecvTos) 
          # segfaults in the sandbox environment
          (final: prev: {
            folly = prev.folly.overrideAttrs (old: {
              doCheck = false;
            });
          })
          # Use bun from nixpkgs master (1.3.9) for opencode compatibility
          (final: prev: {
            bun = pkgs-master.bun;
          })
          # Exclude broken tree-sitter-quint grammar (hash mismatch in nixpkgs)
          (final: prev: {
            tree-sitter-grammars = prev.tree-sitter-grammars // {
              tree-sitter-quint = null;
            };
          })
        ];
      };

      # Build tree-sitter grammars excluding broken ones
      treesit-grammars-filtered = pkgs.emacsPackages.treesit-grammars.with-grammars (grammars:
        builtins.filter (g: g != null && (g.pname or "") != "tree-sitter-quint")
          (builtins.attrValues grammars)
      );
      # Custom Emacs build with tree-sitter grammars
      emacs-with-grammars = pkgs.emacsWithPackagesFromUsePackage {
        config = "";
        defaultInitFile = false;
        alwaysEnsure = true;
        package = pkgs.emacs-gtk;

        extraEmacsPackages = epkgs: with epkgs; [
          # Tree-sitter grammars (filtered to exclude broken ones)
          treesit-grammars-filtered

          # Common packages
          use-package
          envrc
          yaml-mode
          nix-mode
          dockerfile-mode
        ];
      };
    in {
      nixosConfigurations.toph = nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          ruby-packages = nixpkgs-ruby.packages.${system};
          inherit pkgs-master;
          inherit emacs-with-grammars;
        };

        modules = [
          ./configuration.nix
          ./modules/ruby.nix
          ./modules/npm.nix
        ];
      };

      # Expose Ruby packages for direnv
      packages.${system} = nixpkgs-ruby.packages.${system} // {
        default = nixpkgs-ruby.packages.${system}."ruby-4";
      };

      # Expose devShells for each Ruby version
      devShells.${system} = builtins.mapAttrs (name: ruby:
        pkgs.mkShell {
          buildInputs = [
            ruby
            # Build dependencies for Ruby gems with native extensions
            pkgs.libyaml      # for psych gem (YAML)
            pkgs.openssl      # for SSL-related gems
            pkgs.zlib         # for compression
            pkgs.readline     # for readline support
            pkgs.pkg-config   # for finding libraries
            pkgs.gcc          # C compiler
            pkgs.gnumake      # make utility
            pkgs.libffi       # for fiddle gem (FFI)
            pkgs.gtk3         # for glimmer-dsl-libui
          ];

          # Configure gem installation to use a writable directory per Ruby version
          shellHook = ''
          export GEM_HOME="$HOME/.local/share/gem/${name}"
          export GEM_PATH="$GEM_HOME"
          export PATH="$GEM_HOME/bin:$PATH"

          # Add GTK3 and related libraries to LD_LIBRARY_PATH for glimmer-dsl-libui
          export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
                        pkgs.gtk3
                        pkgs.pango
                        pkgs.cairo
                        pkgs.gdk-pixbuf
                        pkgs.glib
                        pkgs.atk
                      ]}:$LD_LIBRARY_PATH"

          mkdir -p "$GEM_HOME"
        '';
        }
      ) nixpkgs-ruby.packages.${system};
    };
}
