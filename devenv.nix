{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  # https://devenv.sh/basics/
  env.GREET = "devenv";

  # https://devenv.sh/packages/
  # packages = [ pkgs.git ];
  packages = with pkgs; [
    mkgmap
    mkgmap-splitter
    osmium-tool
    coreutils
    wget
    expat

    qmapshack
  ];

  env.LD_LIBRARY_PATH = lib.makeLibraryPath (with pkgs; [ expat ]);

  languages.python = {
    enable = true;
    venv.enable = true;
    venv.requirements = ''
      pyhgtmap
    '';
  };

  # https://devenv.sh/languages/
  # languages.rust.enable = true;

  # https://devenv.sh/processes/
  # processes.dev.exec = "${lib.getExe pkgs.watchexec} -n -- ls -la";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts.hello.exec = ''
    echo hello from $GREET
  '';

  # https://devenv.sh/basics/
  enterShell = ''
    echo "========================================="
    hello         # Run scripts directly
    git --version # Use packages
    echo "Garmin Map Development Environment Active!"
    echo "Tools included: mkgmap, splitter, pyhgtmap, osmium"
    echo "========================================="
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
