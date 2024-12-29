pkgs: let
  inherit (pkgs.lib) concatStringsSep imap listToAttrs;
  makeTest = {
    name,
    plugins,
    expectedPluginFiles,
    expectedParsers,
  }: let
    config = let
      base = pkgs.neovimUtils.makeNeovimConfig {inherit plugins;};
    in
      base
      // {
        wrapRc = false;
        wrapperArgs =
          base.wrapperArgs
          ++ [
            "--add-flags"
            "'-u' '${
              pkgs.writeText "init.lua" ''
                function test()
                  local success = true

                  require("nvim-treesitter.configs").setup({})
                  local parsers = require("nvim-treesitter.parsers")
                  for _, p in ipairs({${
                  concatStringsSep "," (map (p: ''"${p}"'') expectedParsers)
                }}) do
                    if not parsers.has_parser(p) then
                      print("${name}: missing parser: " .. p)
                      success = false
                    end
                  end

                  function has_script(scripts, script)
                    local filtered = vim.tbl_filter(
                      function(s)
                        return string.find(s, script, 1, true)
                      end, scripts
                    )
                    return #filtered > 0
                  end
                  local scripts = vim.split(
                    vim.api.nvim_exec("scriptnames", true), "\n", {trimempty = true}
                  )
                  for _, s in ipairs({${
                  concatStringsSep "," (map (p: ''"${p}"'') expectedPluginFiles)
                }}) do
                    if not has_script(scripts, s) then
                      print("${name}: missing plugin script:", s)
                      success = false
                    end
                  end

                  print("${name}-result:", success)
                end

                vim.cmd("autocmd BufEnter * lua test()")
              ''
            }'"
          ];
      };
    nvim = pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped config;
  in
    pkgs.runCommand name {} ''
      tmp=$(mktemp -d)
      cleanup() {
        if [[ -d $tmp ]]; then
          rm -rf "$tmp"
        fi
      }
      trap cleanup EXIT
      HOME=$tmp
      output=$("${nvim}"/bin/nvim -es --cmd "redi! > /dev/stdout" -c "redi end|q!")
      printf "%s\n" "''${output//${name}-result: */}"
      touch $out
      [[ "$(tail -n 1 <<<"$output")" == "${name}-result: true" ]]
    '';
  tests = let
    pluginMarkers = {
      # XXX: neorg doesn't provide ftdetect/norg.lua anymore so neovim has no
      # neorg-specific plugin scripts to source (see :h scriptnames). fixing
      # this test properly will require a different method of verifying plugin
      # installation.
      neorg = "filetype.lua";
      plenary = "plugin/plenary.vim";
      nvim-treesitter = "plugin/nvim-treesitter.lua";
      telescope = "plugin/telescope.lua";
    };
  in [
    {
      # 1. Just neorg — should automatically pull in plugin and parser dependencies
      plugins = with pkgs.vimPlugins; [neorg];
      expectedPluginFiles = with pluginMarkers; [neorg plenary nvim-treesitter];
      expectedParsers = [
        "norg"
        "norg_meta"
      ];
    }
    # 2. Additional parser — should add to our parsers.
    {
      plugins = with pkgs.vimPlugins; [
        neorg
        (nvim-treesitter.withPlugins (p: [p.tree-sitter-bash]))
      ];
      expectedPluginFiles = with pluginMarkers; [neorg plenary nvim-treesitter];
      expectedParsers = ["bash" "norg" "norg_meta"];
    }
    # 3. Requesting just norg parser — should add norg_meta parser.
    {
      plugins = with pkgs.vimPlugins; [
        neorg
        (nvim-treesitter.withPlugins (p: [p.tree-sitter-norg]))
      ];
      expectedPluginFiles = with pluginMarkers; [neorg plenary nvim-treesitter];
      expectedParsers = ["norg" "norg_meta"];
    }
    # 4. Requesting norg and norg-meta parsers — shouldn't lead to duplicates (which
    #    would fail the derivation of the parser dir)
    {
      plugins = with pkgs.vimPlugins; [
        neorg
        (nvim-treesitter.withPlugins
          (p: [p.tree-sitter-norg p.tree-sitter-norg-meta]))
      ];
      expectedPluginFiles = with pluginMarkers; [neorg plenary nvim-treesitter];
      expectedParsers = ["norg" "norg_meta"];
    }
    # 5. Requesting norg and unrelated parser — should add norg-meta.
    {
      plugins = with pkgs.vimPlugins; [
        neorg
        (nvim-treesitter.withPlugins (p: [p.tree-sitter-bash p.tree-sitter-norg]))
      ];
      expectedPluginFiles = with pluginMarkers; [neorg plenary nvim-treesitter];
      expectedParsers = ["norg" "norg_meta" "bash"];
    }
    # 6. withAllGrammars — should include our parsers…
    {
      plugins = with pkgs.vimPlugins; [neorg nvim-treesitter.withAllGrammars];
      expectedPluginFiles = with pluginMarkers; [neorg plenary nvim-treesitter];
      expectedParsers = [
        "norg"
        "norg_meta"
        # exemplary for "all":
        "bash"
        "perl"
      ];
    }
    # 7. …using allGrammars — as in 6.
    {
      plugins = with pkgs.vimPlugins; [
        neorg
        (nvim-treesitter.withPlugins (_: nvim-treesitter.allGrammars))
      ];
      expectedPluginFiles = with pluginMarkers; [neorg plenary nvim-treesitter];
      expectedParsers = [
        "norg"
        "norg_meta"
        # exemplary for "all":
        "bash"
        "perl"
      ];
    }
    # 8. Requesting just neorg-telescope — should pull in all required vim plugins and
    #    our parsers…
    {
      plugins = with pkgs.vimPlugins; [neorg-telescope];
      expectedPluginFiles = with pluginMarkers; [
        telescope
        neorg
        plenary
        nvim-treesitter
      ];
      expectedParsers = ["norg" "norg_meta"];
    }
    # 9. …with explicit neorg request — as in 8. …
    {
      plugins = with pkgs.vimPlugins; [neorg neorg-telescope];
      expectedPluginFiles = with pluginMarkers; [
        telescope
        neorg
        plenary
        nvim-treesitter
      ];
      expectedParsers = ["norg" "norg_meta"];
    }
    # 10. …with explicit parser request — should result in requested parser + ours (+
    #     vim plugin deps as before)…
    {
      plugins = with pkgs.vimPlugins; [
        neorg-telescope
        (nvim-treesitter.withPlugins (p: [p.tree-sitter-bash]))
      ];
      expectedPluginFiles = with pluginMarkers; [
        telescope
        neorg
        plenary
        nvim-treesitter
      ];
      expectedParsers = ["norg" "norg_meta" "bash"];
    }
  ];
in
  listToAttrs (imap
    (i: test: rec {
      name = "test${toString i}";
      value = makeTest (test // {inherit name;});
    })
    tests)
