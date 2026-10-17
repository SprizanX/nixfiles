# aspect for the user "sans"

{ den, ... }:

{
  den.aspects.sans = {
    includes = [
      den._.primary-user
      (den._.user-shell "fish")

      den._.host-aspects
    ];

    nixos =
      { config, ... }:
      {
        users.mutableUsers = false;
        users.users.sans = {
          description = "Sans";
          isNormalUser = true;

          # CHANGE THIS: log in, run `mkpasswd -m sha-512`, then replace this with
          # `hashedPassword = "...";` and delete the initialPassword line.
          initialPassword = "nixos";

          group = "sans";
          extraGroups =
            let
              inherit (builtins) filter hasAttr;
              ifTheyExist = groups: filter (group: hasAttr group config.users.groups) groups;
            in
            (
              [
                "users"
                "video"
                "audio"
                "input"
              ]
              ++ ifTheyExist [
                "data"
                "docker"
                "git"
                "plugdev"
              ]
            );
        };

        users.groups.sans = { };
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          btop
          git

          alacritty
          fuzzel
          kitty
          kitty.terminfo
        ];
      };

    # the user can provide nixos configurations to any host it is included on
    provides.to-hosts.nixos =
      { ... }:
      {
        nix.settings.trusted-users = [ "sans" ];
      };
  };
}
