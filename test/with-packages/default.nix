{ pkgs
, haskell
, stdenv
}:

with stdenv.lib;

let
  pkgSet = haskell.mkNewPkgSet {
    inherit pkgs;
    # generated with:
    #   cabal new-build
    #   plan-to-nix dist-newstyle/cache/plan.json > plan.nix 
    #   cabal-to-nix test-with-packages.cabal > test-with-packages.nix 
    pkg-def = import ./plan.nix;
    pkg-def-overlays = [
      { test-with-packages = ./test-with-packages.nix; }
    ];
    modules = [
      # overrides to fix the build
      {
        packages.transformers-compat.components.library.doExactConfig = true;
      }
    ];
  };

  packages = pkgSet.config.hsPkgs;

in
  stdenv.mkDerivation {
    name = "with-packages-test";

    buildCommand = let
      inherit (packages.test-with-packages.components) library;
      inherit (packages.test-with-packages) devEnv;
    in ''
      ########################################################################
      # test with-packages

      printf "checking that package env has the dependencies... " >& 2
      ${devEnv}/bin/runghc ${./Point.hs}
      echo

      touch $out
    '';

    meta.platforms = platforms.all;
} // { inherit packages pkgSet; }
