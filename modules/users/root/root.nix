# aspect for the user "root"
{
  den.aspects.root.nixos =
    { pkgs, ... }:
    {
      users.mutableUsers = false;
      users.users.root.shell = pkgs.fish;

      # root has no password; log in as your own user and escalate with sudo
      users.users.root.hashedPassword = "!";
    };
}
