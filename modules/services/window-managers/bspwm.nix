{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.xsession.windowManager.bspwm;
  bspwm = cfg.bspwm-package;
  sxhkd = cfg.sxhkd-package;
in {
  options = {
    xsession.windowManager.bspwm = {
      enable = mkEnableOption "Bspwm window manager.";

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
    xsession.windowManager = {
      initExtra = ''
        ${sxhkd}/bin/sxhkd &
      '';
      command = "${bspwm}/bin/bspwm";
    };
  };
}
