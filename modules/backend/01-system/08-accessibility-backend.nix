{ self, inputs, ... }: {

  flake.modules.nixos.system-accessibility-backend =
    {
      config,
      lib,
      ...
    }:

    let
      highContrastPalettes = [
        "windows-highcontrast"
        "windows-highcontrast-light"
        "penumbra-dark-contrast-plus-plus"
        "penumbra-light-contrast-plus-plus"
      ];

    in
    {
      options.ojuny.accessibility = {
        highContrast = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Use a high-contrast base16 palette instead of the normal palette.";
        };
        highContrastPalette = lib.mkOption {
          type = lib.types.enum highContrastPalettes;
          default = "windows-highcontrast";
          description = "High-contrast base16 scheme.";
        };
        iccProfile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "ICC profile applied to every monitor as a build-time output color transform. HDR must be off for the output.";
        };
        reduceMotion = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Disable DMS and Mango window animations.";
        };
        onScreenKeyboard = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Install and run the themed wvkbd on-screen keyboard.";
          };
          auto = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Show the keyboard when a text field takes focus and hide it when focus leaves. Requires zwp_input_method_v2 and a client that implements text-input-v3; other clients use the toggle keybind.";
          };
          tray = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Show a tray icon that toggles the keyboard.";
          };
          portraitHeight = lib.mkOption {
            type = lib.types.ints.positive;
            default = 300;
            description = "Keyboard height in portrait orientation, in pixels.";
          };
          landscapeHeight = lib.mkOption {
            type = lib.types.ints.positive;
            default = 200;
            description = "Keyboard height in landscape orientation, in pixels.";
          };
          rounding = lib.mkOption {
            type = lib.types.ints.unsigned;
            default = 12;
            description = "Corner rounding radius of the keyboard keys, in pixels.";
          };
          fontSize = lib.mkOption {
            type = lib.types.ints.positive;
            default = 20;
            description = "Keyboard label size, in points.";
          };
        };
      };

      config = {

        environment.sessionVariables.QT_ACCESSIBILITY = lib.mkIf config.services.orca.enable "1";
      };
    };

}
