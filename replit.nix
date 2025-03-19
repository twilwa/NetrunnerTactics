{pkgs}: {
  deps = [
    pkgs.postgresql
    pkgs.lsof
    pkgs.xorg.libXcursor
    pkgs.xorg.libXinerama
    pkgs.xorg.libXi
    pkgs.xorg.libXrandr
    pkgs.libGL
    pkgs.libpulseaudio
    pkgs.alsa-lib
    pkgs.which
    pkgs.cacert
    pkgs.bashInteractive
    pkgs.unzip
    pkgs.wget
  ];
}