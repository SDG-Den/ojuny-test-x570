/*
  The global EDITOR default is mkDefault, so any normal-priority definition
  wins. A per-editor defaultEditor switch writes EDITOR and VISUAL at normal
  priority and therefore overrides micro. With no switch on, micro stays.
  Turning on two switches is a configuration error, not a silent winner.
*/

{ self, lib, ... }:

let
  microColorscheme =
    colors:
    lib.concatStringsSep "\n" [
      ''color-link default "${colors.defaultForeground.hex},${colors.defaultBackground.hex}"''
      ''color-link comment "${colors.comments.hex}"''
      ''color-link identifier "${colors.variables.hex}"''
      ''color-link constant "${colors.integers.hex}"''
      ''color-link constant.string "${colors.strings.hex}"''
      ''color-link constant.number "${colors.integers.hex}"''
      ''color-link constant.bool "${colors.integers.hex}"''
      ''color-link statement "${colors.keywords.hex}"''
      ''color-link symbol "${colors.support.hex}"''
      ''color-link symbol.operator "${colors.support.hex}"''
      ''color-link symbol.brackets "${colors.support.hex}"''
      ''color-link symbol.tag "${colors.functions.hex}"''
      ''color-link preproc "${colors.deprecated.hex}"''
      ''color-link type "${colors.classes.hex}"''
      ''color-link special "${colors.support.hex}"''
      ''color-link underlined "underline ${colors.support.hex}"''
      ''color-link error "bold ${colors.variables.hex}"''
      ''color-link todo "bold ${colors.classes.hex}"''
      ''color-link hlsearch "${colors.defaultBackground.hex},${colors.classes.hex}"''
      ''color-link statusline "${colors.defaultForeground.hex},${colors.selectionBackground.hex}"''
      ''color-link statusline.inactive "${colors.darkForeground.hex},${colors.lighterBackground.hex}"''
      ''color-link tabbar "${colors.defaultForeground.hex},${colors.selectionBackground.hex}"''
      ''color-link tabbar.active "${colors.defaultForeground.hex},${colors.selectionBackground.hex}"''
      ''color-link indent-char "${colors.comments.hex}"''
      ''color-link line-number "${colors.darkForeground.hex}"''
      ''color-link current-line-number "${colors.defaultForeground.hex}"''
      ''color-link selection "${colors.defaultBackground.hex},${colors.selectionBackground.hex}"''
      ''color-link gutter "${colors.darkForeground.hex},${colors.lighterBackground.hex}"''
      ''color-link gutter-info "${colors.support.hex}"''
      ''color-link gutter-error "${colors.variables.hex}"''
      ''color-link gutter-warning "${colors.classes.hex}"''
      ''color-link message "${colors.defaultForeground.hex},${colors.defaultBackground.hex}"''
      ''color-link error-message "${colors.variables.hex},${colors.defaultBackground.hex}"''
      ''color-link cursor-line "${colors.lighterBackground.hex}"''
      ''color-link color-column "${colors.lighterBackground.hex}"''
      ''color-link match-brace "${colors.defaultBackground.hex},${colors.classes.hex}"''
      ''color-link scrollbar "${colors.selectionBackground.hex},${colors.defaultBackground.hex}"''
      ''color-link divider "${colors.selectionBackground.hex}"''
      ''color-link diff-added "${colors.strings.hex}"''
      ''color-link diff-modified "${colors.classes.hex}"''
      ''color-link diff-deleted "${colors.variables.hex}"''
      ''color-link tab-error "${colors.variables.hex}"''
      ''color-link trailingws "${colors.variables.hex}"''
    ]
    + "\n";
in
{

  flake.modules.homeManager.users-user-editor =
    { config, pkgs, ... }:
    let
      textMimeTypes = [
        "text/plain"
        "text/markdown"
        "text/x-markdown"
        "text/x-log"
        "application/x-zerosize"
        "application/json"
        "application/yaml"
        "application/x-yaml"
        "application/toml"
        "application/x-toml"
        "text/xml"
        "application/xml"
        "text/css"
        "text/x-shellscript"
        "application/x-shellscript"
        "text/x-sh"
        "text/x-zsh"
        "text/x-python"
        "text/x-csrc"
        "text/x-chdr"
        "text/x-c++src"
        "text/x-c++hdr"
        "text/x-java"
        "text/x-perl"
        "text/x-pascal"
        "text/x-diff"
        "text/x-sql"
        "text/x-php"
        "application/x-php"
        "application/x-httpd-php"
        "text/x-rst"
        "text/x-tex"
        "text/x-lua"
        "text/x-ruby"
        "text/x-nix"
        "text/javascript"
        "application/javascript"
        "application/x-javascript"
      ];
    in
    {
      xdg.enable = true;
      xdg.mimeApps.enable = true;
      xdg.mimeApps.defaultApplications = lib.genAttrs textMimeTypes (_: "ojuny-editor.desktop");

      home.packages = [
        (pkgs.writeShellScriptBin "ojuny-editor" ''
          exec "''${EDITOR:-micro}" "$@"
        '')
      ];

      xdg.desktopEntries.ojuny-editor = {
        name = "Text Editor";
        genericName = "Text Editor";
        comment = "Edit text files in the terminal";
        exec = "ojuny-editor %f";
        icon = "accessories-text-editor";
        terminal = true;
        categories = [
          "Utility"
          "TextEditor"
        ];
        mimeType = textMimeTypes;
      };

      xdg.configFile."xdg-terminals.list".text = "ghostty.desktop\n";

      programs.micro.enable = true;
      programs.micro.settings.colorscheme = "ojuny";

      # Stylix's micro target hard-codes the "simple" colorscheme; disable it so
      # the generated scheme is the only definition.
      stylix.targets.micro.enable = lib.mkForce false;

      xdg.configFile."micro/colorschemes/ojuny.micro".text = microColorscheme (
        self.colors config.lib.stylix.colors
      );

      home.sessionVariables.EDITOR = lib.mkDefault "micro";
      home.sessionVariables.TERMINAL = "ghostty";

      systemd.user.sessionVariables = {
        EDITOR = config.home.sessionVariables.EDITOR;
        TERMINAL = "ghostty";
      };
    };

  flake.modules.nixos.users-user-editor =
    { config, ... }:
    let
      editorSwitches = [
        {
          option = "ojuny.patch.nixvim.defaultEditor";
          enabled = config.ojuny.patch.nixvim.defaultEditor or false;
        }
        {
          option = "ojuny.patch.emacs.defaultEditor";
          enabled = config.ojuny.patch.emacs.defaultEditor or false;
        }
        {
          option = "ojuny.patch.helix.defaultEditor";
          enabled = config.ojuny.patch.helix.defaultEditor or false;
        }
        {
          option = "ojuny.patch.zed.defaultEditor";
          enabled = config.ojuny.patch.zed.defaultEditor or false;
        }
      ];

      enabledEditors = map (entry: entry.option) (builtins.filter (entry: entry.enabled) editorSwitches);
    in
    {
      # nixpkgs sets environment.variables.EDITOR = mkOverride 1000 "nano".
      # Graphical sessions never source hm-session-vars.sh, so the system
      # value is the one they see. Override it at normal priority.
      environment.variables.EDITOR = "micro";

      assertions = [
        {
          assertion = builtins.length enabledEditors <= 1;
          message =
            "Only one editor may own EDITOR, but these are enabled: "
            + lib.concatStringsSep ", " enabledEditors
            + ". Turn off all but one of ojuny.patch.nixvim.defaultEditor, "
            + "ojuny.patch.emacs.defaultEditor, ojuny.patch.helix.defaultEditor "
            + "and ojuny.patch.zed.defaultEditor.";
        }
      ];
    };

}
