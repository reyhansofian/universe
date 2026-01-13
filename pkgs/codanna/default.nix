{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  zlib,
}:

stdenv.mkDerivation rec {
  pname = "codanna";
  version = "0.9.11";

  src = fetchurl {
    url = "https://github.com/bartolli/codanna/releases/download/v${version}/codanna-${version}-linux-x64.tar.xz";
    sha256 = "0a219wib6xhm7dpq3acmiy86cbgrlam1fbi97y9ql7dk4z0m923f";
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    stdenv.cc.cc.lib
    zlib
  ];

  sourceRoot = "codanna-${version}-linux-x64";

  installPhase = ''
    runHook preInstall
    install -Dm755 codanna $out/bin/codanna
    runHook postInstall
  '';

  meta = with lib; {
    description = "Code intelligence for AI assistants - semantic search and relationship tracking";
    homepage = "https://github.com/bartolli/codanna";
    license = licenses.asl20;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "codanna";
  };
}
