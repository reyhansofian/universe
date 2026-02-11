{
  lib,
  rustPlatform,
  fetchFromGitHub,
  cmake,
  pkg-config,
  perl,
  dbus,
  openssl,
  sqlite,
  zlib,
}:

let
  version = "0.19.1";
  src = fetchFromGitHub {
    owner = "gitbutlerapp";
    repo = "gitbutler";
    tag = "release/${version}";
    hash = "sha256-ZCjlN8DF/l1v4AHk2CPB8VcaSuRLVIuOWPUfSn59LiE=";
  };
in
rustPlatform.buildRustPackage {
  pname = "gitbutler-cli";
  inherit version src;

  cargoPatches = [ ./file-id-from-crates-io.patch ];

  cargoHash = "sha256-HiuK8qp3l2676DrK0kqmF2vvktX00Sbv39nk8L8BChQ=";

  cargoBuildFlags = [
    "-p"
    "but"
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
    perl
  ];

  buildInputs = [
    dbus
    openssl
    sqlite
    zlib
  ];

  env = {
    OPENSSL_NO_VENDOR = true;
    RUSTC_BOOTSTRAP = 1;
    RUSTFLAGS = "--cfg tokio_unstable";
  };

  doCheck = false;

  meta = {
    description = "GitButler CLI - Git client for simultaneous branches";
    homepage = "https://gitbutler.com";
    license = lib.licenses.fsl11Mit;
    mainProgram = "but";
    platforms = lib.platforms.linux;
  };
}
