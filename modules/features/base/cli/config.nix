{
  den.aspects.cli-config = {
    homeManager =
      { pkgs, ... }:
      {
        xdg.configFile."ente/config.yaml".source =
          let
            settingsFormat = pkgs.formats.yaml { };
            settings.endpoint.api = "https://api.ente.io";
          in
          settingsFormat.generate "config.yaml" settings;
      };
  };
}
