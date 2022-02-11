{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    neorg = {
      url = "github:nvim-neorg/neorg";
      flake = false;
    };
    neorg-telescope = {
      url = "github:nvim-neorg/neorg";
      flake = false;
    };
  };
  outputs = { nixpkgs, ... }@inputs: {
    overlay = final: prev:
      with inputs; {
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
      };
  };
}
