{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    norg.url = "github:nvim-neorg/tree-sitter-norg";
    norg-meta.url = "github:nvim-neorg/tree-sitter-norg-meta";

    neorg = {
      url = "github:nvim-neorg/neorg";
      flake = false;
    };
    neorg-telescope = {
      url = "github:nvim-neorg/neorg-telescope";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, ... }@inputs: {
    overlay = final: prev:
      with inputs; let
        grammars = {
          tree-sitter-norg = norg.defaultPackage.${final.system};
          tree-sitter-norg-meta = norg-meta.defaultPackage.${final.system};
        };
      in
      {
        vimPlugins = prev.vimPlugins // {
          neorg = prev.vimUtils.buildVimPluginFrom2Nix {
            pname = "neorg";
            version = neorg.rev;
            src = neorg;
            buildInputs = [ prev.vimPlugins.plenary-nvim ];
          };
          neorg-telescope = prev.vimUtils.buildVimPluginFrom2Nix {
            pname = "neorg-telescope";
            version = neorg-telescope.rev;
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
