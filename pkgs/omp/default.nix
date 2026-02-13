{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  gcc-unwrapped,
  glibc,
  bash-language-server,
}:

let
  version = "11.14.5";

  src-bin = fetchurl {
    url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/omp-linux-x64";
    hash = "sha256-JAh/aVjrHMv+vbuisDKm6ovGgE+R9jJrcfmFIQaCv+c=";
  };

  src-natives = fetchurl {
    url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/pi_natives.linux-x64.node";
    hash = "sha256-QCxK+4edE87OgnbT4oZZeiqc/qldkA5JoG63sNXdJog=";
  };
in
stdenv.mkDerivation {
  pname = "omp";
  inherit version;

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/lib/omp $out/bin
    install -m 755 ${src-bin} $out/lib/omp/omp
    install -m 644 ${src-natives} $out/lib/omp/pi_natives.linux-x64.node

    makeWrapper $out/lib/omp/omp $out/bin/omp \
      --set LD_LIBRARY_PATH "${
        lib.makeLibraryPath [
          gcc-unwrapped.lib
          glibc
        ]
      }" \
      --prefix PATH : "${lib.makeBinPath [ bash-language-server ]}"
  '';

  dontStrip = true;
  dontPatchELF = true;

  doCheck = false;

  meta = {
    description = "Oh-my-pi: batteries-included AI coding agent CLI (fork of pi-mono)";
    homepage = "https://github.com/can1357/oh-my-pi";
    license = lib.licenses.mit;
    mainProgram = "omp";
    platforms = [ "x86_64-linux" ];
  };
}
