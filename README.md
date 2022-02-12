# Neorg overlay for [Nixpkgs](https://github.com/NixOS/nixpkgs)

This is a Nixpkgs overlay that gives Nix users access to unstable versions of Neorg and its associated projects.

Nixpkgs already packages Neorg and the NFF Tree-sitter parser, however those are updated very rarely. This is a problem for rapidly growing projects such as Neorg and can cause the plugin and parser to go out-of-sync. This overlay is updated automatically every 2 hours and, apart from the base plugin and TS parser, provides additional Neorg-related packages.

## Installation

For documentation on how overlays work and how to use them, refer to the [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/#chap-overlays).

**Please note that as of right now only flake-based systems are supported**, an example of which you can see below.

## Example

The following minimal NixOS [flake](https://nixos.wiki/wiki/Flakes) configures Neovim with Neorg and Tree-sitter support using [Home Manager](https://github.com/nix-community/home-manager):

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    neorg-overlay.url = "github:nvim-neorg/nixpkgs-neorg-overlay";
  };
  outputs = { self, nixpkgs, home-manager, neorg, ... }: {
    nixosConfigurations.machine = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        home-manager.nixosModules.home-manager
        {
          nixpkgs.overlays = [ neorg-overlay.overlay ];
          home-manager.users.bandithedoge = {
            programs.neovim = {
              enable = true;
              plugins = with pkgs.vimPlugins; [
                # If you want to install all available parsers, the following also works:
                # (nvim-treesitter.withPlugins (p: builtins.attrValues p))
                # This includes the meta and table parsers, too.
                (nvim-treesitter.withPlugins (p: with p; [
                  # Keep calm and don't :TSInstall
                  tree-sitter-lua
                  tree-sitter-norg
                  tree-sitter-norg-meta
                ]))
                neorg
              ];
              extraConfig = ''
                lua << EOF
                  require("nvim-treesitter.configs").setup {
                    highlight = {
                      enable = true,
                    }
                  }

                  require("neorg").setup {
                    load = {
                      ["core.defaults"] = {}
                    }
                  }
                EOF
              '';
            };
          };
        }
      ];
    };
  };
}
```

## Package list

- [`vimPlugins.neorg`](https://github.com/nvim-neorg/neorg)
- [`vimPlugins.neorg-telescope`](https://github.com/nvim-neorg/neorg-telescope)
- [`tree-sitter-grammars.norg`](https://github.com/nvim-neorg/tree-sitter-norg)
- [`tree-sitter-grammars.norg-meta`](https://github.com/nvim-neorg/tree-sitter-norg-meta)
- [`tree-sitter-grammars.norg-table`](https://github.com/nvim-neorg/tree-sitter-norg-table)
