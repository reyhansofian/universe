{ pkgs, config, lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "thunderbolt"
    "vmd"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "rtsx_usb_sdmmc"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "snd-seq" "snd-rawmidi" "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/a13fc1ad-d770-41a7-8161-844f84b36691";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/00CC-BBF5";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  environment.systemPackages = with pkgs; [
    pulseaudio
    pavucontrol
    paprefs
    portaudio
    jack2
  ];
  security.rtkit.enable = true;
  services = {
    pulseaudio = {
      enable = false;
      package = pkgs.pulseaudioFull.override {
        jackaudioSupport = true;
        advancedBluetoothCodecs = true;
      }; # Enable extra codecs (AAC, APTX, APTX-HD and LDAC.)
      extraConfig = ''
        load-module module-dbus-protocol
        # # For container
        load-module module-native-protocol-unix auth-anonymous=1 socket=/run/user/1000/pulse/pulpul
      '';
    };
  };
  services.pipewire = {
    enable = true;
    wireplumber.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 44100;
        "default.clock.quantum" = 512;
        "default.clock.min-quantum" = 512;
        "default.clock.max-quantum" = 512;
      };
    };
  };
  users.groups = { audio.members = [ "reyhan" ]; };
  services.udev.extraRules = ''
    KERNEL=="rtc0", GROUP="audio"
    KERNEL=="hpet", GROUP="audio"
  '';

  security.pam.loginLimits = [
    {
      domain = "@audio";
      item = "memlock";
      type = "-";
      value = "unlimited";
    }
    {
      domain = "@audio";
      item = "rtprio";
      type = "-";
      value = "99";
    }
    {
      domain = "@audio";
      item = "nofile";
      type = "soft";
      value = "99999";
    }
    {
      domain = "@audio";
      item = "nofile";
      type = "hard";
      value = "524288";
    }
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  networking.interfaces.wlo1.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
  # bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
    settings.General.Experimental = true; # bluetooth percentage
  };
}
