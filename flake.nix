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
            overlays = [ rust.overlays.oxalica rust.overlays.nightly ];
            pkgs = import nixpkgs {
              inherit system overlays;
            };
            # Some insane stuff I have to do to use Rust Nightly, which is
            # required by Serde
            mozilla_rust_channel = (pkgs.rustChannelOf {
              channel = "nightly";
            }
            );
            new_rustc = mozilla_rust_channel.rust;
            new_cargo = mozilla_rust_channel.cargo;
            new_fetchCargoTarball = pkgs.rustPlatform.fetchCargoTarball.override {
              cargo = new_cargo;
            };
            nightly_buildRustPackage = pkgs.rustPlatform.buildRustPackage.override {
              cargo = new_cargo;
              rustc = new_rustc;
              fetchCargoTarball = new_fetchCargoTarball;
            };
          in
          {
            packages = rec
            {
              # Generate the HTML from the JSON files
              generator = nightly_buildRustPackage {
                pname = "http-status-codes-site-generator";
                version = "0.1";
                cargoLock = {
                  lockFile = ./static-site-generator/Cargo.lock;
                };
                src = pkgs.lib.cleanSource ./static-site-generator;
              };

              # Store the generated website in the nix-store
              website = pkgs.stdenv.mkDerivation
                {
                  name = "website-${pkgName}";
                  src = ./static-site-generator;
                  buildInputs = [
                    # To build and run the template engine that regenerates the website
                    # pkgs.rust-nightly-toolchain
                    generator
                  ];

                  installPhase = ''
                    # Run the generator packaged above to generate HTML files from the JSON files
                    mkdir -p result
                    ${generator}/bin/http-status-codes-static-site-generator web result
                    # Copy the resulting files to the nix-store
                    cp -r result $out
                  '';
                };
            };

            devShells = {
              default = pkgs.mkShell {
                buildInputs = [
                  # To easily serve and test the static webpages
                  pkgs.miniserve
                  # To build and run the template engine that regenerates the website
                  pkgs.rust-nightly-toolchain
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
            config =
              let
                root = packages."${pkgs.system}".website;
              in
              {
                # Add the website to the system's packages
                environment.systemPackages = [ packages.${pkgs.system}.website ];

                # Configure a virtual host on nginx
                services.nginx.virtualHosts.${domain} = lib.mkIf cfgcheck {
                  forceSSL = true;
                  enableACME = true;
                  acmeRoot = null;

                  extraConfig = ''
                    error_page 400 /400.html;
                    error_page 401 /401.html;
                    error_page 402 /402.html;
                    error_page 403 /403.html;
                    error_page 404 /404.html;
                    error_page 405 /405.html;
                    error_page 406 /406.html;
                    error_page 407 /407.html;
                    error_page 408 /408.html;
                    error_page 409 /409.html;
                    error_page 410 /410.html;
                    error_page 411 /411.html;
                    error_page 412 /412.html;
                    error_page 413 /413.html;
                    error_page 414 /414.html;
                    error_page 415 /415.html;
                    error_page 416 /416.html;
                    error_page 417 /417.html;
                    error_page 418 /418.html;
                    error_page 421 /421.html;
                    error_page 422 /422.html;
                    error_page 426 /426.html;
                  '';

                  locations = {
                    "/" = {
                      root = "${root}";
                      extraConfig = ''
                        try_files $uri $uri.html
                      '';
                    };

                    "/400.html" = {
                      root = "${root}";
                    };
                    "/400" = {
                      root = "${root}";
                      return = "400";
                    };

                    "/401.html" = {
                      root = "${root}";
                    };
                    "/401" = {
                      root = "${root}";
                      return = "401";
                    };

                    "/402.html" = {
                      root = "${root}";
                    };
                    "/402" = {
                      root = "${root}";
                      return = "402";
                    };

                    "/403.html" = {
                      root = "${root}";
                    };
                    "/403" = {
                      root = "${root}";
                      return = "403";
                    };

                    "/404.html" = {
                      root = "${root}";
                    };
                    "/404" = {
                      root = "${root}";
                      return = "404";
                    };

                    "/405.html" = {
                      root = "${root}";
                    };
                    "/405" = {
                      root = "${root}";
                      return = "405";
                    };

                    "/406.html" = {
                      root = "${root}";
                    };
                    "/406" = {
                      root = "${root}";
                      return = "406";
                    };

                    "/407.html" = {
                      root = "${root}";
                    };
                    "/407" = {
                      root = "${root}";
                      return = "407";
                    };

                    "/408.html" = {
                      root = "${root}";
                    };
                    "/408" = {
                      root = "${root}";
                      return = "408";
                    };

                    "/409.html" = {
                      root = "${root}";
                    };
                    "/409" = {
                      root = "${root}";
                      return = "409";
                    };
                  };
                };
              };
          };
      };
    };
}


