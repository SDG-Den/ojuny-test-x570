/* @menu
   displayname = "Users";
   icon = "avatar-default-symbolic";
   order = 10;
   description = "User Accounts";
   category = "01-Users";
*/

{ self, inputs, ... }: {

  flake.modules.nixos.users = { pkgs, ... }: {

    imports = [ inputs.home-manager.nixosModules.home-manager self.modules.nixos.system-ssh-test ];

    config = {
      /* @option widget = "users"; label = "Accounts"; homeManager = true; */
      users.users = {
        den = {
          isNormalUser = true;
          uid = 1000;
          description = "Primary account";
          extraGroups = [ "networkmanager" "wheel" "video" "input" ];
          hashedPassword = "$y$j9T$LHb7EpvEry4N9JRa62oV31$dgMmZlyG4kF/d7AxZlGJLoV.bBhIlPuOyr0HfiW2/5D";
          openssh.authorizedKeys.keys = [ ];
          shell = pkgs.zsh;
        };
      };

      home-manager.users = {
        den = {
          home.stateVersion = "26.11";
        };
      };
    };

  };

}
