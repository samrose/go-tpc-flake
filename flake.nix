{
  description = "A toolbox to benchmark workloads for TiDB";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        go-tpc = self.packages.${system}.default;
      in
      {
        packages.default = pkgs.buildGoModule rec {
          pname = "go-tpc";
          version = "1.0.11";

          src = pkgs.fetchFromGitHub {
            owner = "pingcap";
            repo = "go-tpc";
            rev = "v${version}";
            sha256 = "sha256-1eo68nqHUiX3mX7ahswxBPjQI7N9VjB1sT451i22T/0=";
          };

          vendorHash = "sha256-JInXHnHW5jfKism5OscYSJJjBBB7URYLSVpo4EJ/HAs=";

          meta = with pkgs.lib; {
            description = "A toolbox to benchmark workloads for TiDB";
            homepage = "https://github.com/pingcap/go-tpc";
            license = licenses.asl20;
            maintainers = with maintainers; [ ];
            mainProgram = "go-tpc";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            go
            go-tpc
            delve
            shellcheck
          ];
        };

        apps.default = {
          type = "app";
          program = "${pkgs.writeScriptBin "run-tpcc" ''
            #!${pkgs.bash}/bin/bash
            export PATH="${go-tpc}/bin:$PATH"
            exec ${./scripts/run-tpcc.sh} "$@"
          ''}/bin/run-tpcc";
        };
      }
    );
}