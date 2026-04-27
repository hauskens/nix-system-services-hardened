{ ... }:
{
  systemd.services.SERVICE_NAME.serviceConfig = {
    # ========== Privilege Restriction ==========
    NoNewPrivileges = true;
    RestrictSUIDSGID = true;
    RestrictRealtime = true;
    LockPersonality = true;

    # ========== Filesystem Protection ==========
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateTmp = true;
    PrivateMounts = true;
    PrivateDevices = true;
    PrivateIPC = true;
    UMask = 0077;

    # ========== Kernel / System Protection ==========
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectKernelLogs = true;
    ProtectControlGroups = true;
    ProtectProc = "invisible";
    ProtectClock = true;
    ProtectHostname = true;

    # ========== Network Isolation ==========
    PrivateNetwork = true;
    RestrictAddressFamilies = [
      "AF_UNIX"
    ];
    IPAddressDeny = [
      "0.0.0.0/0"
      "::/0"
    ];

    # ========== System Call Filtering ==========
    SystemCallArchitectures = "native";
    SystemCallErrorNumber = "EPERM";
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
      "~@resources"
      "~@privileged"
    ];

    # ========== Capability Control ==========
    CapabilityBoundingSet = "";
    RestrictNamespaces = true;
    MemoryDenyWriteExecute = true;

    # ========== Device Access ==========
    DevicePolicy = "closed";
    KeyringMode = "private";
  };
}
