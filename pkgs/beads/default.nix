{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "beads";
  version = "0.47.0";

  src = fetchFromGitHub {
    owner = "steveyegge";
    repo = "beads";
    rev = "v${version}";
    hash = "sha256-p7l4wla+8vQqBUeNyoGKWhBQO8m53A4UNSghQQCvk2A=";
  };

  vendorHash = "sha256-pY5m5ODRgqghyELRwwxOr+xlW41gtJWLXaW53GlLaFw=";

  # The main binary is bd
  subPackages = [ "cmd/bd" ];

  # Skip tests - they fail in sandboxed build environment
  # (TestDaemonAutostart_StartDaemonProcess_Stubbed fails)
  doCheck = false;

  ldflags = [ "-s" "-w" ];

  meta = with lib; {
    description = "A distributed, git-backed graph issue tracker for AI agents";
    homepage = "https://github.com/steveyegge/beads";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "bd";
  };
}
