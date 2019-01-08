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
    #   cabal-to-nix test-haddock.cabal > test-haddock.nix 
    pkg-def = import ./plan.nix;
    pkg-def-overlays = [
      { test-haddock = ./test-haddock.nix; }
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
      inherit (packages.test-haddock.components) library;
    in ''
      ########################################################################
      # test haddock

      doc="${toString library.doc}"
      docDir="${toString (library.haddockDir library)}"

      # exeDoc="$ disabled {toString packages.test-haddock.components.exes.test-haddock.doc}"
      # printf "checking that executable output does not have docs ... " >& 2
      # echo $exeDoc
      # test "$exeDoc" = ""

      printf "checking that documentation directory was built... " >& 2
      echo "$doc"
      test -n "$doc"

      printf "checking that documentation was generated... " >& 2
      grep hello "$docDir/TestHaddock.html" > /dev/null
      echo yes

      touch $out
    '';

    meta.platforms = platforms.all;
} // { inherit packages pkgSet; }
