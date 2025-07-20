# /hosts/modules/virtualization.nix
{ config, pkgs, ... }:
{
  # This single block sets ALL kernel parameters correctly.
  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
    # --- IMPORTANT: REPLACE WITH YOUR GPU'S PCI IDs ---
    "vfio-pci.ids=VENDOR_ID:DEVICE_ID,VENDOR_ID:DEVICE_ID"
  ];

  boot.blacklistedKernelModules = [ "nvidia" "nouveau" "amdgpu" ];

  nixpkgs.overlays = [
    (final: prev: {
      qemu_custom = prev.qemu.overrideAttrs (oldAttrs: {
        pname = "qemu-from-source";
        version = "9.1.0";
        src = prev.fetchurl {
          url = "https://download.qemu.org/qemu-9.1.0.tar.xz";
          # --- IMPORTANT: REPLACE WITH THE REAL HASH ---
          # To get the real hash, try building with this fake one.
          # Nix will fail and tell you the correct hash to use.
          hash = "sha256-0000000000000000000000000000000000000000000000000000";
        };
      });
    })
  ];

  virtualisation = {
    libvirtd.enable = true;
    package = pkgs.qemu_custom;
  };
  programs.virt-manager.enable = true;
  environment.systemPackages = [ pkgs.virt-manager ];
}
