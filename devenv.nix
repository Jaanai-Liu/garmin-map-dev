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
    jdk21

    qmapshack
    gpxsee
  ];

  env.LD_LIBRARY_PATH = lib.makeLibraryPath (with pkgs; [ expat ]);

  languages.python = {
    enable = true;
  };

  # pyhgtmap is not in nixpkgs, so we manage it via a local venv
  env.VENV_PATH = "$DEVENV_ROOT/.venv";

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
    # Setup Python virtual environment with pyhgtmap
    if [ ! -d "$VENV_PATH" ]; then
      echo ">>> Creating Python venv with pyhgtmap..."
      python -m venv "$VENV_PATH"
      source "$VENV_PATH/bin/activate"
      pip install pyhgtmap
    else
      source "$VENV_PATH/bin/activate"
    fi

    echo "========================================="
    hello
    git --version
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
