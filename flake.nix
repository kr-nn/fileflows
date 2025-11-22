{
  description = "fileflows flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    runserver = ''dotnet $out/share/Server/FileFlows.Server.dll \$\@'';
  in {

    nixosModules.default = self.nixosModules.fileflows;
    nixosModules.fileflows = import ./fileflows.nix;

    packages.x86_64-linux.default = self.packages.x86_64-linux.fileflows;
    packages.x86_64-linux.fileflows = pkgs.stdenv.mkDerivation rec {

      pname = "fileflows";
      version = "25.10.9.6001";

      src = pkgs.fetchzip {
        url = "https://fileflows.com/downloads/Zip/${version}";
        sha256 = "sha256-fvMEjrivAyi9lH6/dpq1Kpryc7JcqbxtpLhYoYpL56U=";
        stripRoot = false;
        extension = "zip";
      };

      nativeBuildInputs = [ pkgs.makeWrapper ];
      buildInputs = [ pkgs.webkitgtk_4_1 pkgs.dotnet-sdk_8 ];

      installPhase = ''
        runHook preInstall

        mkdir -p $out/share $out/bin
        cp -r ./* $out/share

        echo ${runserver} > $out/share/run-server.sh
        chmod +x $out/share/run-server.sh
        makeWrapper $out/share/run-server.sh $out/bin/fileflows \
          --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.dotnet-sdk_8 ]} \
          --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [ pkgs.webkitgtk_4_1 pkgs.zlib ]}

        runHook postInstall
      '';

      meta = with pkgs.lib; {
        description = "FileFlows media file processing server";
        homepage = "https://fileflows.com/";
        #license = licenses.unfreeRedistributable or licenses.unfree;
        platforms = platforms.linux;
        mainProgram = "fileflows";
      };
    };
  };
}
