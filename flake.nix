{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    norg.url = "github:nvim-neorg/tree-sitter-norg";
    norg-meta.url = "github:nvim-neorg/tree-sitter-norg-meta";
    norg-table.url = "github:nvim-neorg/tree-sitter-norg-table";

    neorg = {
      url = "github:nvim-neorg/neorg";
      flake = false;
    };
    neorg-telescope = {
      url = "github:nvim-neorg/neorg";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, ... }@inputs: {
    overlay = final: prev:
      with inputs; let
        grammars = {
          tree-sitter-norg = norg.defaultPackage;
          tree-sitter-norg-meta = norg-meta.defaultPackage;
          tree-sitter-norg-table = norg-table.defaultPackage;
        };
      in
      {
        vimPlugins = prev.vimPlugins // {
          neorg = prev.vimUtils.buildVimPluginFrom2Nix {
            name = "neorg";
            src = neorg;
            buildInputs = [ prev.vimPlugins.plenary-nvim ];
          };
          neorg-telescope = prev.vimUtils.buildVimPluginFrom2Nix {
            name = "neorg-telescope";
            src = neorg-telescope;
            buildInputs = [ prev.vimPlugins.telescope-nvim final.vimPlugins.neorg ];
          };
        };
        tree-sitter = prev.tree-sitter // {
          allGrammars = (prev.lib.lists.remove prev.tree-sitter.builtGrammars.tree-sitter-norg prev.tree-sitter.allGrammars) ++ builtins.attrValues grammars;
          builtGrammars = prev.tree-sitter.builtGrammars // grammars;
        };
        tree-sitter-grammars = prev.tree-sitter-grammars // grammars;
      };
  };
}
