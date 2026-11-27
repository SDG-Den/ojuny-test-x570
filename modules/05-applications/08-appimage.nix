/*
  @menu
  displayname = "App format compatibility";
  icon = "application-x-executable-symbolic";
  order = 80;
  description = "AppImage support and an optional experimental Raven runtime for Windows files";
  category = "05-Applications";
*/

{ self, inputs, ... }: {

  flake.modules.nixos.applications-appimage =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ self.modules.nixos.applications-appimage-backend ];

      config = {
        # @option widget = "switch"; label = "AppImage support"; group = "AppImage"; description = "Run AppImage files by double-clicking and from the terminal.";
        ojuny.appimage.enable = true;

        # @option widget = "switch"; label = "Register with binfmt"; group = "AppImage"; advanced = true; description = "Let the kernel run executable AppImage files through appimage-run.";
        ojuny.appimage.binfmt = true;

        # @option widget = "packages"; label = "AppImage environment includes"; group = "AppImage"; description = "Packages added to the AppImage runtime environment. They are not installed system-wide; they are available only to AppImage applications.";
        ojuny.appimage.extraPackages = [ ];
      };
    };

  flake.modules.nixos.applications-appimage-raven =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.raven.nixosModules.default
        self.modules.nixos.applications-appimage-raven-backend
      ];

      options.ojuny.raven = {
        enable = lib.mkEnableOption "the optional experimental Raven Windows runtime";
        printers = lib.mkEnableOption "printing from Raven programs to Linux CUPS queues";
        vst3 = lib.mkEnableOption "the VST 3 plugin bridge in Raven";
      };

      config = {
        # @option widget = "switch"; label = "Raven for Windows files (experimental)"; group = "Windows applications"; groupOrder = 20; order = 10; description = "Optional and experimental. Opens .exe, .msi and .bat files with Raven instead of Wine. Raven is not guaranteed to run a given program, and some installers and games will fail. .bat files are best-effort and interactive scripts need a terminal. This does not affect Steam or Proton.";
        ojuny.raven.enable = false;

        # @option widget = "switch"; label = "Print to CUPS printers"; group = "Windows applications"; groupOrder = 20; order = 11; visibleWhen.path = "ojuny.raven.enable"; visibleWhen.equals = true; description = "Adds CUPS client tools to the Raven environment, so a prefix printer target of cups:QUEUE can hand receipt and report jobs to a Linux print queue as raw data.";
        ojuny.raven.printers = false;

        # @option widget = "switch"; label = "VST 3 plugin bridge"; group = "Windows applications"; groupOrder = 20; order = 12; visibleWhen.path = "ojuny.raven.enable"; visibleWhen.equals = true; description = "Builds Raven's VST 3 bridge, raven-vsthost.exe and raven-vst.so, so a Linux host can run Windows VST 3 plugins through Raven.";
        ojuny.raven.vst3 = false;
      };
    };

}
