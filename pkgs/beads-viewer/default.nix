{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "beads-viewer";
  version = "0.10.2";

  src = fetchFromGitHub {
    owner = "Dicklesworthstone";
    repo = "beads_viewer";
    rev = "v${version}";
    hash = lib.fakeHash;
  };

  vendorHash = lib.fakeHash;

  # The main binary is bv
  subPackages = [ "cmd/bv" ];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  meta = with lib; {
    description = "Terminal-based task management interface for Beads issue tracking system";
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
