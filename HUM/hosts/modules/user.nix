# /hosts/modules/user.nix
{
  users.users.your-username = {
    isNormalUser = true;
    description = "Your Name";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" ];
  };

  home-manager.users.your-username = { pkgs, ... }: {
    home.packages = with pkgs; [ firefox ];
    programs.git = {
      enable = true;
      userName = "Your Name";
      userEmail = "your-email@example.com";
    };
    home.stateVersion = "24.05";
  };
}
