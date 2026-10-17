{ self, lib, ... }:

{
  den.aspects.ssh = {
    settings.forwardDiskKey = lib.mkEnableOption "forwarding the disk-backed Ed25519 key to trusted devices";

    nixos =
      { config, ... }:
      let
        inherit (builtins)
          attrNames
          filter
          listToAttrs
          map
          pathExists
          ;
        inherit (lib) mkDefault optional;

        publicKey = name: ../../hosts/${name}/ssh_host_ed25519_key.pub;
        hostNames = filter (name: pathExists (publicKey name)) (attrNames self.nixosConfigurations);
      in
      {
        services.openssh = {
          enable = true;
          settings = {
            AllowAgentForwarding = true;
            GatewayPorts = "clientspecified";
            PasswordAuthentication = false;
            PermitRootLogin = "prohibit-password";
            X11Forwarding = true;
          };

          hostKeys = [
            {
              path = "/etc/ssh/ssh_host_ed25519_key";
              type = "ed25519";
            }
            {
              openSSHFormat = true;
              path = "/etc/ssh/ssh_host_rsa_key";
              type = "rsa";
            }
          ];
        };

        services.fail2ban = {
          enable = mkDefault true;
          maxretry = 5;
        };

        programs.ssh = {
          knownHosts = listToAttrs (
            map (name: {
              inherit name;
              value = {
                publicKeyFile = publicKey name;
                extraHostNames = optional (name == config.networking.hostName) "localhost";
              };
            }) hostNames
          );

          startAgent = false;
        };

        # mobile shell
        programs.mosh.enable = true;
      };

    homeManager =
      {
        user,
        lib,
        ...
      }:
      {
        programs.ssh =
          let
            username = user.userName;
            identityFiles = [ "~/.ssh/id_ed25519" ];
            mkHost = args: { User = username; IdentitiesOnly = true; } // args;
          in
          {
            enable = true;
            enableDefaultConfig = false;

            settings = {
              "aur.archlinux.org" = mkHost {
                User = "aur";
                IdentityFile = "~/.ssh/aur.pub";
              };
              "github.com" = mkHost {
                IdentityFile = identityFiles;
                User = "git";
              };

              "*" = {
                ForwardAgent = false;
                AddKeysToAgent = "no";
                Compression = false;
                ServerAliveInterval = 0;
                ServerAliveCountMax = 3;
                HashKnownHosts = false;
                UserKnownHostsFile = "~/.ssh/known_hosts";
                ControlMaster = "no";
                ControlPath = "~/.ssh/master-%r@%n:%p";
                ControlPersist = "no";
              };
            };
          };

        # generate a key with `ssh-keygen -t ed25519` before using any of this
        home.file.".ssh/config".force = true;

        # materialize the config because openssh rejects nix store ownership in uid-isolated terminals
        home.activation.materializeSshConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          sshConfig="$HOME/.ssh/config"
          sshConfigSource="$(readlink -f "$sshConfig")"
          sshConfigTmp="$sshConfig.hm-tmp"

          run rm -f "$sshConfigTmp"
          run install -m 0400 "$sshConfigSource" "$sshConfigTmp"
          run mv -f "$sshConfigTmp" "$sshConfig"
        '';
      };
  };
}
