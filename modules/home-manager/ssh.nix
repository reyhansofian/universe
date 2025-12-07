{ lib, osConfig, ... }: {
  home.activation = {
    change-ssh-permission = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # $DRY_RUN_CMD chmod $VERBOSE_ARG 600 ~/.ssh/id_ed.pub
      # $DRY_RUN_CMD chmod $VERBOSE_ARG 600 ~/.ssh/user-ubuntu-vm.pub
      # $DRY_RUN_CMD chmod $VERBOSE_ARG 600 ~/.ssh/gitlab.pub
    '';
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        userKnownHostsFile = "~/.ssh/known_hosts";
        hashKnownHosts = false;
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
      };
      "github.com" = {
        hostname = "github.com";
        identityFile = "~/.ssh/id_ed";
        identitiesOnly = true;
        user = "git";
        extraOptions = { AddKeysToAgent = "yes"; };
      };
      "gitlab.com" = {
        hostname = "gitlab.com";
        identityFile = "~/.ssh/gitlab";
        identitiesOnly = true;
        user = "git";
        extraOptions = { AddKeysToAgent = "yes"; };
      };
      "ubuntu.local" = {
        hostname = "vm.local";
        identityFile = "~/.ssh/user-ubuntu-vm";
        identitiesOnly = true;
        user = "user";
        extraOptions = { AddKeysToAgent = "yes"; };
      };
      "bitbucket.org-noice" = {
        hostname = "bitbucket.org";
        identityFile = "~/.ssh/bitbucket-noice";
        identitiesOnly = true;
        user = "git";
        extraOptions = { AddKeysToAgent = "yes"; };
      };
    };
    extraConfig = ''
      Include config.d/*
    '';
  };
}

