{ lib, stdenv, haskellLib }:

{ ghcEnv, shellHook }:
let
  inherit (ghcEnv) baseGhc package;
  ghcCommand' = if baseGhc.isGhcjs or false then "ghcjs" else "ghc";
  ghcCommand = "${baseGhc.targetPrefix}${ghcCommand'}";
  ghcCommandCaps = lib.toUpper ghcCommand';
in stdenv.mkDerivation {
  name = "shell-for-${package.identifier.name}";

  CABAL_CONFIG = package.configFiles + "/cabal.config";

  "NIX_${ghcCommandCaps}" = "${ghcEnv}/bin/${ghcCommand}";
  "NIX_${ghcCommandCaps}PKG" = "${ghcEnv}/bin/${ghcCommand}-pkg";
  "NIX_${ghcCommandCaps}_LIBDIR" = if baseGhc.isHaLVM or false
    then "${ghcEnv}/lib/HaLVM-${baseGhc.version}"
    else "${ghcEnv}/lib/${ghcCommand}-${baseGhc.version}";
  # fixme: docs, haddock, hoogle
  # NIX_${ghcCommandCaps}_DOCDIR" = package.configFiles;

  nativeBuildInputs = [ ghcEnv ];
  phases = ["installPhase"];
  installPhase = "echo $nativeBuildInputs $buildInputs > $out";

  passthru = {
    ghc = ghcEnv;
  };
}
