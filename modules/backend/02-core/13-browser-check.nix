{ ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      seeders = import ../../../packages/browser-storage-seeders.nix { inherit pkgs; };
    in
    {
      checks.browser-storage =
        pkgs.runCommand "check-browser-storage"
          {
            nativeBuildInputs = [
              pkgs.bash
              pkgs.coreutils
              pkgs.gnugrep
            ];
          }
          ''
            bash ${
              builtins.path {
                path = ../../../tests/check-browser-storage.sh;
                name = "check-browser-storage.sh";
              }
            } ${seeders.chromium}/bin/seed-extension-storage ${seeders.firefox}/bin/seed-firefox-extension-storage
            touch $out
          '';
    };
}
