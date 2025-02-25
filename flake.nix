{
  description = "Website for generating and learning about HTTP status codes.";

  inputs = {
    rust.url = "git+https://git.irlqt.net/crow/rust-flake.git";
    utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { rust, utils, nixpkgs, ... }:
    let
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
              let
                pkgName = "http-status-codes";
              in
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
    };
}


