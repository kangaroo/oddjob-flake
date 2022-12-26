{
  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, flake-utils, ... }@inputs:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = inputs.nixpkgs.legacyPackages."${system}";
        lib = inputs.nixpkgs.lib;
      in
      {
        packages.default = pkgs.stdenv.mkDerivation rec {
          name = "oddjob";
          version = "0.34.7";

          src = pkgs.fetchurl {
            url =
            "https://pagure.io/oddjob/archive/${name}-${version}/oddjob-${name}-${version}.tar.gz";
            sha256 = "sha256-SUOsMH55HtEsk5rX0CXK0apDObTj738FGOaL5xZRnIM=";
          };

          nativeBuildInputs = with pkgs; [ autoreconfHook pkg-config ];
          buildInputs = with pkgs; [ libxml2 dbus pam systemd ];

          postPatch = ''
            substituteInPlace configure.ac --replace 'SYSTEMDSYSTEMUNITDIR=`pkg-config --variable=systemdsystemunitdir systemd 2> /dev/null`' "SYSTEMDSYSTEMUNITDIR=${placeholder "out"}"
            substituteInPlace configure.ac --replace 'SYSTEMDSYSTEMUNITDIR=`pkg-config --variable=systemdsystemunitdir systemd`' "SYSTEMDSYSTEMUNITDIR=${placeholder "out"}"
          '';

          configureFlags = [
            "--prefix=${placeholder "out"}"
            "--sysconfdir=${placeholder "out"}/etc"
            "--with-selinux-acls=no"
            "--with-selinux-labels=no"
          ];

          postConfigure = ''
            substituteInPlace src/oddjobd.c --replace "globals.selinux_enabled" "FALSE"
          '';

          meta = with lib; {
            description = "Odd Job Daemon";
            homepage = "https://pagure.io/oddjob";
            changelog = "https://pagure.io/oddjob/blob/c539e931b6dac3f1dd51cd54696adf918fad0053/f/ChangeLog";
            mainProgram = "oddjobd";
            license = licenses.bsd0;
            platforms = platforms.linux;
            maintainers = with maintainers; [ kangaroo ];
          };
        };
      });
}
