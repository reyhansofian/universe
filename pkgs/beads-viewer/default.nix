{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "beads-viewer";
  version = "0.13.0";

  src = fetchFromGitHub {
    owner = "Dicklesworthstone";
    repo = "beads_viewer";
    rev = "v${version}";
    hash = "sha256-lFJPZFeXnhLhfGvZybpSJOi/11xcaP8bn+6KpxljlPM=";
  };

  vendorHash = "sha256-V8Bl5lW9vd7o1ZcQ6rvs3WJ1ueYX7xKnHTyRAASHlng=";

  # The main binary is bv
  subPackages = [ "cmd/bv" ];

  # Skip tests to avoid environment-specific failures in sandboxed builds
  doCheck = false;

  ldflags = [ "-s" "-w" "-X main.version=${version}" ];

  meta = with lib; {
    description =
      "Terminal-based task management interface for Beads issue tracking system";
    longDescription = ''
      Beads Viewer (bv) is a TUI application that visualizes Beads projects as
      dependency graphs rather than simple lists, enabling graph-theoretic analysis
      for better work prioritization. Built with the Bubble Tea framework.
    '';
    homepage = "https://github.com/Dicklesworthstone/beads_viewer";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "bv";
  };
}
