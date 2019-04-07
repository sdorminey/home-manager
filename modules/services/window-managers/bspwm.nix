{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.xsession.windowManager.bspwm;
  bspwm = cfg.bspwm-package;
  sxhkd = cfg.sxhkd-package;

  start-sxhkd = pkgs.writeShellScriptBin "start-sxhkd" ''
    . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
    ${sxhkd}/bin/sxhkd &
  '';

  # Adapted from ${bspwm}/share/doc/bspwm/examples/bspwmrc:
  default-bspwmrc = let script = ''
      bspc monitor -d I II III IV V VI VII VIII IX X

      bspc config border_width         2
      bspc config window_gap          12

      bspc config split_ratio          0.52
      bspc config borderless_monocle   true
      bspc config gapless_monocle      true
    ''; in writeShellScriptBin "bspwmrc" script;

  default-sxhkdrc = builtins.readFile (builtins.toPath "${bspwm}/share/doc/bspwm/examples/sxhkdrc");

in {
  options = {
    xsession.windowManager.bspwm = {
      enable = mkEnableOption "Bspwm window manager.";

      bspwmrc = mkOption {
        type = types.path;
        default = default-bspwmrc;
        defaultText = "Adapted default bspwmrc.";
        description = "Config shell script for bspwm.";
      };

      sxhkdrc = mkOption {
        type = types.path;
        default = default-sxhkdrc;
        defaultText = "Default config file.";
        description = "Config shell script for sxhkd..";
      };

      bspwm-package = mkOption {
        type = types.package;
        default = pkgs.bspwm;
        defaultText = "pkgs.bspwm";
        description = "Package to use for running the Bspwm window manager.";
      };

      sxhkd-package = mkOption {
        type = types.package;
        default = pkgs.sxhkd;
        defaultText = "pkgs.sxhkd";
        description = "Package to use for running the Skhkd keyboard handler.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ bspwm sxhkd ];

    xdg.configFile."bspwm/bspwmrc".source = cfg.bspwmrc;
    xdg.configFile."sxhkd/sxhkdrc".source = cfg.sxhkdrc;

    xsession.windowManager.command = "${bspwm}/bin/bspwm";

    systemd.user.services.sxhkd = {
      Unit = {
        Description = "Simple X Hotkey Daemon";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
        X-Restart-Triggers = [ config.xdg.configFile."sxhkd/sxhkdrc".source ];
      };

      Service = {
        Type = "forking";
#        Environment = "PATH=${cfg.sxhkd-package}/bin:${cfg.bspwm-package}/bin:/run/wrappers/bin SHELL=${pkgs.runtimeShell}";
        ExecStart = "${start-sxhkd}/bin/start-sxhkd";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
