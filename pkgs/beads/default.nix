{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "beads";
  version = "0.47.2";

  src = fetchFromGitHub {
    owner = "steveyegge";
    repo = "beads";
    rev = "v${version}";
    hash = "sha256-yj57dWrxNO8hp1q/W3VX9bQbvJZhUdLpvDqhfwJM7UA=";
  };

  vendorHash = "sha256-YU+bRLVlWtHzJ1QPzcKJ70f+ynp8lMoIeFlm+29BNPE=";

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
