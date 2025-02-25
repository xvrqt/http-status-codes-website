{
  description = "Website for generating and learning about HTTP status codes.";

  inputs = {
    rust.url = "git+https://git.irlqt.net/crow/rust-flake.git";
    utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { rust, utils, nixpkgs, ... }:
    let
      pkgName = "http-status-codes";
      wrapped = utils.lib.eachDefaultSystem
        (system:
          let
            overlays = [ rust.overlays.oxalica rust.overlays.default ];
            pkgs = import nixpkgs {
              inherit system overlays;
            };

          in
          {
            packages =
              {
                website = pkgs.stdenv.mkDerivation
                  {
                    name = "website-${pkgName}";
                    src = ./static-site-generator;

                    buildInputs = [
                      # To build and run the template engine that regenerates the website
                      pkgs.rust-toolchain
                    ];

                    buildPhase = ''
                      cargo run --release
                    '';

                    installPhase = ''
                      cp -r $src $out
                    '';
                  };
              };

            nixosModules = { };

            devShells = {
              default = pkgs.mkShell {
                buildInputs = [
                  # To easily serve and test the static webpages
                  pkgs.miniserve
                  # To build and run the template engine that regenerates the website
                  pkgs.rust-toolchain
                ];

                shellHook = ''
                  # Rebuild the website
                  cd static-site-generator
                  cargo run
                  cd ..
                  clear
                  # Check if the server is already working
                  if pgrep -x miniserve >> /dev/null
                  then
                    echo "Server already running."
                  else
                    # Start the server, set a trap to kill it on exit
                    miniserve -p 1234 -d monokai static-site-generator/result/ > logs/server.log 2>&1 & 
                    WEB_PID=$!
                    trap "kill -9 $WEB_PID" EXIT
                    echo "Server is running at: localhost:1234"
                    echo "Logs file started at: logs/server.log"
                  fi
                '';
              };
            };
          }
        );
      packages = wrapped.packages;
      devShells = wrapped.devShells;
    in
    rec
    {
      inherit packages devShells;
      /* So other flakes (i.e. website-flake) can create options and configs for this flake */
      metadata = rec {
        name = "http-status-codes";
        pkgName = "website-${name}";
        description = "A website which generates HTTP status codes and provides information webpages about them";
        defaults = {
          subDomain = "http";
          domain = "${defaults.subDomain}.xvrqt.com";
        };
      };
      nixosModules = {
        default = { lib, pkgs, config, ... }:
          let
            # Check if both the website service is enabled, and this specific site is enabled.
            cfgcheck = config.services.websites.enable && config.services.websites.sites.${pkgName}.enable;
            # Website url
            domain = config.services.websites.sites.${pkgName}.domain;
          in
          {
            # Create the option to enable this site, and set its domain name
            options = {
              services = {
                websites = {
                  sites = {
                    http-status-codes = {
                      enable = lib.mkEnableOption "Learn about, and generate HTTP status codes.";
                      domain = lib.mkOption {
                        type = lib.types.str;
                        default = "http.xvrqt.com";
                        example = "gateway.xvrqt.com";
                        description = "Domain name for the website. In the form: sub.domain.tld, domain.tld";
                      };
                    };
                  };
                };
              };
            };
            config = {
              # Add the website to the system's packages
              environment.systemPackages = [ packages.${pkgs.system}.website ];

              # Configure a virtual host on nginx
              services.nginx.virtualHosts.${domain} = lib.mkIf cfgcheck {
                forceSSL = true;
                enableACME = true;
                acmeRoot = null;
                locations."/" = {
                  root = "${packages.${pkgs.system}.website}";
                };
              };
            };
          };
      };
    };
}


