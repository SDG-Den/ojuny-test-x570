{ pkgs }:
{
  firefox = pkgs.writeShellApplication {
    name = "seed-firefox-extension-storage";
    runtimeInputs = [ pkgs.coreutils ];
    text = builtins.readFile ../scripts/seed-firefox-extension-storage.sh;
  };

  chromium = pkgs.stdenv.mkDerivation {
    name = "ojuny-seed-extension-storage";
    src = ../scripts/seed-extension-storage.cc;
    dontUnpack = true;
    buildInputs = [ pkgs.leveldb ];
    buildPhase = ''
      runHook preBuild
      $CXX -O2 -std=c++17 -o seed-extension-storage $src \
        -I${pkgs.leveldb}/include -L${pkgs.leveldb}/lib -lleveldb
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      install -Dm755 seed-extension-storage $out/bin/seed-extension-storage
      runHook postInstall
    '';
  };
}
