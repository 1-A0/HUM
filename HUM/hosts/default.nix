# /hosts/default.nix
{
  imports = [
    ../modules/base.nix
    ../modules/disk-config.nix
    ../modules/hyprland.nix
    ../modules/virtualization.nix
    ../modules/backup.nix
    ../modules/user.nix
  ];

  # Set the system's hardware clock and services to UTC.
  time.timeZone = "Etc/UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  # This hostname MUST match the name in flake.nix
  networking.hostName = "gandiva";
  networking.networkmanager.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data are taken.
  system.stateVersion = "24.05";
}
