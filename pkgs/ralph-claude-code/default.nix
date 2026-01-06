{
  lib,
  stdenv,
  makeWrapper,
  bash,
  tmux,
  jq,
  git,
  coreutils,
  gnugrep,
  gnused,
  findutils,
  ralph-claude-code-src,
}:

stdenv.mkDerivation {
  pname = "ralph-claude-code";
  version = "0.9.0";

  src = ralph-claude-code-src;

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [
    bash
    tmux
    jq
    git
  ];

  installPhase = ''
    runHook preInstall

    # Create directories
    mkdir -p $out/bin
    mkdir -p $out/share/ralph/{lib,templates/specs}

    # Copy library files
    cp -r lib/*.sh $out/share/ralph/lib/

    # Copy templates
    cp templates/AGENT.md $out/share/ralph/templates/
    cp templates/PROMPT.md $out/share/ralph/templates/
    cp templates/fix_plan.md $out/share/ralph/templates/
    touch $out/share/ralph/templates/specs/.gitkeep

    # Copy core scripts
    cp ralph_loop.sh $out/share/ralph/
    cp ralph_monitor.sh $out/share/ralph/
    cp ralph_import.sh $out/share/ralph/
    cp setup.sh $out/share/ralph/

    # Make scripts executable
    chmod +x $out/share/ralph/*.sh

    # Create wrapper for ralph command
    cat > $out/bin/ralph <<'EOF'
#!/usr/bin/env bash
export RALPH_HOME="@out@/share/ralph"
exec "@bash@/bin/bash" "@out@/share/ralph/ralph_loop.sh" "$@"
EOF

    # Create wrapper for ralph-monitor command
    cat > $out/bin/ralph-monitor <<'EOF'
#!/usr/bin/env bash
export RALPH_HOME="@out@/share/ralph"
exec "@bash@/bin/bash" "@out@/share/ralph/ralph_monitor.sh" "$@"
EOF

    # Create wrapper for ralph-setup command
    cat > $out/bin/ralph-setup <<'EOF'
#!/usr/bin/env bash
export RALPH_HOME="@out@/share/ralph"
exec "@bash@/bin/bash" "@out@/share/ralph/setup.sh" "$@"
EOF

    # Create wrapper for ralph-import command
    cat > $out/bin/ralph-import <<'EOF'
#!/usr/bin/env bash
export RALPH_HOME="@out@/share/ralph"
exec "@bash@/bin/bash" "@out@/share/ralph/ralph_import.sh" "$@"
EOF

    # Make wrappers executable
    chmod +x $out/bin/*

    # Substitute placeholders in wrapper scripts
    substituteInPlace $out/bin/ralph \
      --replace '@out@' "$out" \
      --replace '@bash@' "${bash}"

    substituteInPlace $out/bin/ralph-monitor \
      --replace '@out@' "$out" \
      --replace '@bash@' "${bash}"

    substituteInPlace $out/bin/ralph-setup \
      --replace '@out@' "$out" \
      --replace '@bash@' "${bash}"

    substituteInPlace $out/bin/ralph-import \
      --replace '@out@' "$out" \
      --replace '@bash@' "${bash}"

    # Wrap binaries with runtime dependencies
    for prog in $out/bin/*; do
      wrapProgram $prog \
        --prefix PATH : ${
          lib.makeBinPath [
            bash
            tmux
            jq
            git
            coreutils
            gnugrep
            gnused
            findutils
          ]
        }
    done

    runHook postInstall
  '';

  meta = with lib; {
    description = "Autonomous AI development system for Claude Code";
    homepage = "https://github.com/frankbria/ralph-claude-code";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.unix;
  };
}
