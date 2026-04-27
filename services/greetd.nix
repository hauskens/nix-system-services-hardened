{ ... }:
{
  systemd.services.greetd.serviceConfig = {
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    ProtectHome = "read-only";
    ProtectClock = true;
    ProtectHostname = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectKernelLogs = true;
    ProtectControlGroups = true;
    ProtectProc = "invisible";
    ProcSubset = "pid";
    PrivateTmp = true;
    PrivateMounts = true;
    PrivateNetwork = true;
    PrivateDevices = true;
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    RestrictAddressFamilies = [
      "AF_UNIX"
    ];
    MemoryDenyWriteExecute = true;
    LockPersonality = true;
    KeyringMode = "private";
    CapabilityBoundingSet = [
      "CAP_SETUID"
      "CAP_SETGID"
      "CAP_SYS_TTY_CONFIG"
      "CAP_CHOWN"
      "CAP_FOWNER"
      "CAP_DAC_OVERRIDE"
    ];
    DevicePolicy = "closed";
    SystemCallFilter = [
      "~@clock"
      "~@cpu-emulation"
      "~@debug"
      "~@module"
      "~@mount"
      "~@obsolete"
      "~@raw-io"
      "~@reboot"
      "~@swap"
    ];
    SystemCallArchitectures = "native";
    UMask = 0077;
    IPAddressDeny = [
      "0.0.0.0/0"
      "::/0"
    ];
  };
}
