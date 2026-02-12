{
  lib,
  rustPlatform,
  fetchFromGitHub,
  cmake,
  pkg-config,
  openssl,
  zlib,
}:

let
  version = "0.7.1";
in
rustPlatform.buildRustPackage {
  pname = "tuicr";
  inherit version;

  src = fetchFromGitHub {
    owner = "agavra";
    repo = "tuicr";
    tag = "v${version}";
    hash = "sha256-48zXpng4/YlmRXU1eR5jDrL62Fq/9syLBEqqf7LhSkQ=";
  };

  cargoHash = "sha256-cM3IRQtek98s6FrM0eVMTDgQgXPWwwoCJ1i2m702Dzg=";

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    openssl
    zlib
  ];

  env = {
    OPENSSL_NO_VENDOR = true;
  };

  doCheck = false;

  meta = {
    description = "TUI for reviewing AI-generated code diffs";
    homepage = "https://github.com/agavra/tuicr";
    license = lib.licenses.mit;
    mainProgram = "tuicr";
    platforms = lib.platforms.linux;
  };
}
