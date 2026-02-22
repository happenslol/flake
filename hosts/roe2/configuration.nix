{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  networking = {
    hostId = "640c2c0b";
    hostName = "roe2";
  };

  boot = {
    loader = {
      timeout = 0;
      efi.canTouchEfiVariables = true;

      systemd-boot = {
        enable = true;
        configurationLimit = 50;
      };
    };

    kernelParams = [
      "quiet"
      "splash"
      "loglevel=3"
      "nowatchdog"
      "systemd.show_status=auto"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "rd.systemd.show_status=false"
    ];
  };

  nix.settings = {
    cores = 6;
    max-jobs = 4;
  };

  hardware.bluetooth = {
    enable = true;
    settings.General.experimental = true;
  };

  systemd.services = {
    pia-vpn.after = ["systemd-networkd-wait-online.service"];

    transmission-dirs = {
      description = "Create Transmission download directories";
      requiredBy = ["transmission.service"];
      before = ["transmission.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/mkdir -p /srv/transmission/.incomplete'";
      };
    };

    transmission = {
      bindsTo = ["pia-vpn.service"];
      after = ["pia-vpn.service"];
      serviceConfig = {
        NetworkNamespacePath = "/var/run/netns/pia";
        BindReadOnlyPaths = ["/etc/netns/pia/resolv.conf:/etc/resolv.conf"];
      };
    };

    transmission-rpc-proxy = {
      description = "Forward Transmission RPC from pia namespace to host";
      after = ["transmission.service"];
      bindsTo = ["transmission.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:9091,fork,reuseaddr EXEC:'${pkgs.iproute2}/bin/ip netns exec pia ${pkgs.socat}/bin/socat STDIO TCP\\:127.0.0.1\\:9091'";
        Restart = "always";
      };
    };

    radarr = {
      bindsTo = ["pia-vpn.service"];
      after = ["pia-vpn.service"];
      serviceConfig = {
        NetworkNamespacePath = "/var/run/netns/pia";
        BindReadOnlyPaths = ["/etc/netns/pia/resolv.conf:/etc/resolv.conf"];
      };
    };

    sonarr = {
      bindsTo = ["pia-vpn.service"];
      after = ["pia-vpn.service"];
      serviceConfig = {
        NetworkNamespacePath = "/var/run/netns/pia";
        BindReadOnlyPaths = ["/etc/netns/pia/resolv.conf:/etc/resolv.conf"];
      };
    };

    radarr-rpc-proxy = {
      description = "Forward Radarr from pia namespace to host";
      after = ["radarr.service"];
      bindsTo = ["radarr.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:7878,fork,reuseaddr EXEC:'${pkgs.iproute2}/bin/ip netns exec pia ${pkgs.socat}/bin/socat STDIO TCP\\:127.0.0.1\\:7878'";
        Restart = "always";
      };
    };

    sonarr-rpc-proxy = {
      description = "Forward Sonarr from pia namespace to host";
      after = ["sonarr.service"];
      bindsTo = ["sonarr.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:8989,fork,reuseaddr EXEC:'${pkgs.iproute2}/bin/ip netns exec pia ${pkgs.socat}/bin/socat STDIO TCP\\:127.0.0.1\\:8989'";
        Restart = "always";
      };
    };
  };

  environment.etc."netns/pia/resolv.conf".text = "nameserver 10.0.0.243\n";

  services = {
    blueman.enable = true;

    # udev = {
    #   # vial and zmk studio
    #   packages = with pkgs; [via vial];
    #   extraRules = ''
    #     SUBSYSTEM=="usb", ATTR{idVendor}=="1d50", ATTR{idProduct}=="615e", MODE="0666", GROUP="plugdev", TAG+="uaccess"
    #   '';
    # };

    nginx = {
      enable = true;
      virtualHosts = {
        "transmission.local" = {
          listen = [
            {
              addr = "127.0.0.1";
              port = 80;
            }
          ];
          locations."/".proxyPass = "http://127.0.0.1:9091";
        };
        "radarr.local" = {
          listen = [
            {
              addr = "127.0.0.1";
              port = 80;
            }
          ];
          locations."/".proxyPass = "http://127.0.0.1:7878";
        };
        "sonarr.local" = {
          listen = [
            {
              addr = "127.0.0.1";
              port = 80;
            }
          ];
          locations."/".proxyPass = "http://127.0.0.1:8989";
        };
        "jellyfin.local" = {
          listen = [
            {
              addr = "127.0.0.1";
              port = 80;
            }
          ];
          locations."/".proxyPass = "http://127.0.0.1:8096";
        };
      };
    };

    transmission = {
      enable = true;
      home = "/var/lib/transmission";
      package = pkgs.transmission_4;
      settings = {
        download-dir = "/srv/transmission";
        incomplete-dir = "/srv/transmission/.incomplete";
        incomplete-dir-enabled = true;
        rpc-bind-address = "0.0.0.0";
        rpc-whitelist-enabled = false;
      };
    };

    radarr.enable = true;
    sonarr.enable = true;
    jellyfin.enable = true;

    pia-vpn = {
      enable = true;
      environmentFile = config.sops.secrets.pia.path;
      certificateFile = ../../pia.ca.rsa.4096.crt;
      namespace = "pia";
      region = "de-frankfurt";
      portForward = {
        enable = true;
        script = ''
          ${pkgs.curl}/bin/curl -s http://127.0.0.1:9091/transmission/rpc \
            -H "$(${pkgs.curl}/bin/curl -s http://127.0.0.1:9091/transmission/rpc | ${pkgs.gnugrep}/bin/grep -oP 'X-Transmission-Session-Id: \S+')" \
            -d '{"method":"session-set","arguments":{"peer-port":'"$port"'}}'
        '';
      };
    };
  };

  users.groups.media = {};

  users.users = {
    happens.extraGroups = ["transmission" "media"];
    radarr.extraGroups = ["media"];
    sonarr.extraGroups = ["media"];
    transmission.extraGroups = ["media"];
    jellyfin.extraGroups = ["media"];
  };

  networking.hosts = {
    "127.0.0.1" = ["transmission.local" "radarr.local" "sonarr.local" "jellyfin.local"];
  };

  systemd.services.corsair-h150i-liquidctl = {
    enable = true;
    description = "CPU AIO Fan Control";
    wantedBy = ["default.target"];

    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.liquidctl}/bin/liquidctl initialize --pump-mode quiet
      ${pkgs.liquidctl}/bin/liquidctl set fan speed 30 40 40 50 45 60 50 90
      ${pkgs.liquidctl}/bin/liquidctl set led color fixed 444444
    '';
  };
}
