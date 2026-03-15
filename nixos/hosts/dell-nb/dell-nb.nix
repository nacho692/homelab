{ config, pkgs, lib, ... }:
{
  services.power-profiles-daemon.enable = true;

  services.logind.settings.Login.HandleLidSwitch = "suspend-then-hibernate";
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
  services.logind.settings.Login.HandleLidSwitchDocked = "ignore";

  services.logind.settings.Login.HandlePowerKey = "hibernate";
  services.logind.settings.Login.HandlePowerKeyLongPress = "poweroff";

  boot.kernelParams = ["mem_sleep_default=deep"];

  systemd.sleep.extraConfig = ''
    HibernateDelaySec=10m
    SuspendState=mem
  '';

  systemd.services.hibernate-fix = {
    enable = true;
    unitConfig = {
      Description = "Intel HID module unloading to prevent it interrupting hibernation";
      Before = [ "suspend-then-hibernate.target" "hibernate.target" ];
      StopWhenUnneeded = "yes";
    };

    wantedBy = [ "suspend-then-hibernate.target" "hibernate.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
      ExecStart = "-${pkgs.kmod}/bin/rmmod intel_hid";
      ExecStop = "-${pkgs.kmod}/bin/modprobe intel_hid";
    };
  };
}
