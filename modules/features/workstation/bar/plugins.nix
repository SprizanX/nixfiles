{
  den.aspects.noctalia-plugins = {
    homeManager =
      {
        pkgs,
        ...
      }:
      {
        home.packages = with pkgs; [
          glib # gdbus for plugins
          gpu-screen-recorder # for screen recorder plugin
        ];

        # plugin sources are configured in noctalia-config.toml under [plugins]
      };
  };
}
