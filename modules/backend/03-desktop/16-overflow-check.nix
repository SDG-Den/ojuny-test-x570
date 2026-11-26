{ ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      source = pkgs.lib.cleanSource ../../..;
    in
    {
      checks.overflow-layout =
        pkgs.runCommand "check-overflow-layout"
          {
            nativeBuildInputs = [
              pkgs.bash
              pkgs.coreutils
              pkgs.jq
            ];
          }
          ''
            bash ${source}/tests/check-overflow-layout.sh ${source}/modules/backend/03-desktop/overflow-layout.sh
            touch $out
          '';
    };
}
