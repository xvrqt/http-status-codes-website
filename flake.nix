{
  description = "Website for generating and learning about HTTP error codes.";

  inputs = {
    rust.url = "git+https://git.irlqt.net/crow/rust-flake.git";
    utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { rust, utils, nixpkgs, ... }:
    utils.lib.eachDefaultSystem
      (system:
        let
          overlays = [ rust.overlays.oxalica rust.overlays.default ];
          pkgs = import nixpkgs {
            inherit system overlays;
          };
        in
        {
          packages = { };
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
                project_directory=$(pwd)/web
                clear
                if pgrep -x miniserve >> /dev/null
                then
                  echo "Server already running."
                else
                  # Start the server, set a trap to kill it on exit
                  miniserve -p 1234 -d monokai web/ > logs/server.log 2>&1 &
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
}


