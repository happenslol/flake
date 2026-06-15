{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.nixvirt.nixosModules.default
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

  # The domain (its "hardware") is declarative; the qcow2 contents are not.
  # One-time host setup before first boot:
  #   sudo install -d /var/lib/libvirt/images /var/lib/libvirt/qemu/nvram
  #   sudo qemu-img create -f qcow2 /var/lib/libvirt/images/win.qcow2 80G
  #   place a Windows 11 ISO at /var/lib/libvirt/images/Win11.iso
  # Then `virsh start win` (or start it from virt-manager) and install.
  # Once Windows + the virtio-win drivers are in, comment out install_vol and
  # install_virtio below and rebuild to detach the install media.
  virtualisation.libvirt = {
    enable = true;
    swtpm.enable = true;
    connections."qemu:///system" = {
      # Default NAT network providing the virbr0 bridge the guest attaches to.
      # active = true keeps it up after every rebuild and boot, so the VM has
      # internet for activation with no manual `virsh net-start default`.
      networks = [
        {
          active = true;
          definition = inputs.nixvirt.lib.network.writeXML (
            inputs.nixvirt.lib.network.templates.bridge {
              name = "default";
              uuid = "fe11ee37-1620-478b-b509-584d1608ae93";
              bridge_name = "virbr0";
              subnet_byte = 122;
            }
          );
        }
      ];

      domains = [
        {
          # null: define the domain but leave start/stop to you, so a system
          # rebuild never yanks the VM out from under you mid-use.
          active = null;
          definition = inputs.nixvirt.lib.domain.writeXML (
            inputs.nixvirt.lib.domain.templates.windows {
              name = "win";
              uuid = "6da3b73b-7f3b-46c1-b405-05581b2f2a68";
              net_iface_mac = "52:54:00:8a:c7:ab";
              memory = {
                count = 8;
                unit = "GiB";
              };
              vcpu = {count = 8;};
              storage_vol = "/storage/win.qcow2";
              nvram_path = "/var/lib/libvirt/qemu/nvram/win.fd";
              # Windows + virtio driver media — comment both out post-install.
              install_vol = "/var/lib/libvirt/images/Win11.iso";
              install_virtio = true;
              virtio_net = true; # netkvm driver, installed from the virtio-win ISO
              virtio_video = false; # QXL: most reliable SPICE display for a desktop guest
            }
          );
        }
      ];
    };
  };

  programs.virt-manager.enable = true;

  # File sharing with the "win" VM over its NAT bridge: the guest reaches the
  # host at 192.168.122.1, so map \\192.168.122.1\win in Windows. Bound to
  # virbr0 only so the share isn't exposed on the LAN (host firewall is off).
  services.samba = {
    enable = true;
    settings = {
      global = {
        security = "user";
        "map to guest" = "Bad User"; # no password prompt from the VM
        interfaces = "lo virbr0";
        "bind interfaces only" = "yes";
      };
      win = {
        path = "/srv/win";
        writable = "yes";
        "guest ok" = "yes";
        "force user" = "happens";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
    };
  };

  # smbd must start after NixVirt brings up the default network (which creates
  # virbr0); otherwise bind-interfaces-only has no interface to bind to.
  systemd.services.samba-smbd = {
    after = ["nixvirt.service"];
    wants = ["nixvirt.service"];
  };

  systemd.tmpfiles.rules = ["d /srv/win 0775 happens users -"];

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
      partOf = ["pia-vpn.service"];
      serviceConfig = {
        NetworkNamespacePath = "/var/run/netns/pia";
        BindReadOnlyPaths = ["/etc/netns/pia/resolv.conf:/etc/resolv.conf"];
      };
    };

    transmission-rpc-proxy = {
      description = "Forward Transmission RPC from pia namespace to host";
      after = ["transmission.service"];
      bindsTo = ["transmission.service"];
      partOf = ["transmission.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:9091,fork,reuseaddr EXEC:'${pkgs.iproute2}/bin/ip netns exec pia ${pkgs.socat}/bin/socat STDIO TCP\\:127.0.0.1\\:9091'";
        Restart = "always";
      };
    };

    radarr = {
      bindsTo = ["pia-vpn.service"];
      after = ["pia-vpn.service"];
      partOf = ["pia-vpn.service"];
      serviceConfig = {
        NetworkNamespacePath = "/var/run/netns/pia";
        BindReadOnlyPaths = ["/etc/netns/pia/resolv.conf:/etc/resolv.conf"];
        UMask = lib.mkForce "0002";
      };
    };

    sonarr = {
      bindsTo = ["pia-vpn.service"];
      after = ["pia-vpn.service"];
      partOf = ["pia-vpn.service"];
      serviceConfig = {
        NetworkNamespacePath = "/var/run/netns/pia";
        BindReadOnlyPaths = ["/etc/netns/pia/resolv.conf:/etc/resolv.conf"];
        UMask = lib.mkForce "0002";
      };
    };

    bazarr = {
      bindsTo = ["pia-vpn.service"];
      after = ["pia-vpn.service"];
      partOf = ["pia-vpn.service"];
      serviceConfig = {
        NetworkNamespacePath = "/var/run/netns/pia";
        BindReadOnlyPaths = ["/etc/netns/pia/resolv.conf:/etc/resolv.conf"];
        UMask = lib.mkForce "0002";
      };
    };

    radarr-rpc-proxy = {
      description = "Forward Radarr from pia namespace to host";
      after = ["radarr.service"];
      bindsTo = ["radarr.service"];
      partOf = ["radarr.service"];
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
      partOf = ["sonarr.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:8989,fork,reuseaddr EXEC:'${pkgs.iproute2}/bin/ip netns exec pia ${pkgs.socat}/bin/socat STDIO TCP\\:127.0.0.1\\:8989'";
        Restart = "always";
      };
    };

    bazarr-rpc-proxy = {
      description = "Forward Bazarr from pia namespace to host";
      after = ["bazarr.service"];
      bindsTo = ["bazarr.service"];
      partOf = ["bazarr.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:6767,fork,reuseaddr EXEC:'${pkgs.iproute2}/bin/ip netns exec pia ${pkgs.socat}/bin/socat STDIO TCP\\:127.0.0.1\\:6767'";
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
        "bazarr.local" = {
          listen = [
            {
              addr = "127.0.0.1";
              port = 80;
            }
          ];
          locations."/".proxyPass = "http://127.0.0.1:6767";
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
    bazarr.enable = true;
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
    happens.extraGroups = ["transmission" "media" "libvirtd"];
    radarr.extraGroups = ["media"];
    sonarr.extraGroups = ["media"];
    bazarr.extraGroups = ["media"];
    transmission.extraGroups = ["media"];
    jellyfin.extraGroups = ["media"];
  };

  networking.hosts = {
    "127.0.0.1" = ["transmission.local" "radarr.local" "sonarr.local" "bazarr.local" "jellyfin.local"];
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
