{ self, inputs, ... }: {
  perSystem = { nixpkgs, pkgs, system, icons, branches, ... }:
    let
      nixvimLib = inputs.nixvim.lib;
      helpers = nixvimLib.nixvim // {
        mkLuaFunWithName = name: lua:
          # lua
          ''
            function ${name}()
              ${lua}
            end
          '';

        mkLuaFun = lua: # lua
          ''
            function()
              ${lua}
            end
          '';
      };
      nixvim' = inputs.nixvim.legacyPackages.${system};
      nixvimModule = {
        inherit pkgs;
        # vimPlugins.avante-nvim = branches.stable.vimPlugins.avante-nvim;
        module = {
          imports = [ (import ./config) ];
          # Disable man pages generation to avoid ansible-language-server error
          enableMan = false;
        };
        # You can use `extraSpecialArgs` to pass additional arguments to your module files
        extraSpecialArgs = { inherit icons branches helpers system self; };
      };
      nvim = nixvim'.makeNixvimWithModule nixvimModule;
      nvimCheck =
        nixvimLib.${system}.check.mkTestDerivationFromNixvimModule nixvimModule;
    in {
      # packages.x86_64-linux.nvim.config.nixpkgs.pkgs.vimPlugins.avante-nvim
      checks = {
        # Run `nix flake check .` to verify that your config is not broken
        nvim = nvimCheck;
      };

      packages = {
        # Lets you run `nix run .` to start nixvim
        inherit nvim;
      };
    };
}
