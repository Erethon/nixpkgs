{
  lib,
  stdenv,
  writeScript,
  ncurses5,
  callPackage,
  buildFHSEnv,
  unwrapped ? callPackage ./runtime.nix { },
}:

buildFHSEnv {
  pname = "houdini";
  inherit (unwrapped) version;

  # houdini spawns hserver (and other license tools) that is supposed to live beyond the lifespan of houdini process
  dieWithParent = false;

  # houdini needs to communicate with hserver process that it seem to be checking to be present in running processes
  unsharePid = false;

  targetPkgs =
    pkgs:
    with pkgs;
    [
      libGLU
      libGL
      alsa-lib
      fontconfig
      zlib
      libpng
      dbus
      nss
      nspr
      expat
      pciutils
      libxkbcommon
      libudev0-shim
      tbb
      xwayland
      qt5.qtwayland
      net-tools # needed by licensing tools
      bintools # needed for ld and other tools, so ctypes can find/load sos from python
      ocl-icd # needed for opencl
      numactl # needed by hfs ocl backend
      zstd # needed from 20.0
    ]
    ++ (with xorg; [
      libICE
      libSM
      libXmu
      libXi
      libXt
      libXext
      libX11
      libXrender
      libXcursor
      libXfixes
      libXrender
      libXcomposite
      libXdamage
      libXtst
      libxcb
      libXScrnSaver
      libXrandr
      libxcb
      xcbutil
      xcbutilimage
      xcbutilrenderutil
      xcbutilcursor
      xcbutilkeysyms
      xcbutilwm
    ]);

  passthru = {
    inherit unwrapped;
  };

  extraInstallCommands =
    let
      executables = [
        "bin/houdini" # houdini flavours
        "bin/houdinicore"
        "bin/houdinifx"
        "bin/hgpuinfo" # houdini ocl config tool
        "bin/hotl" # hda/otl manipulation tool
        "bin/hython" # hython
        "bin/hkey" # license administration
        "bin/husk" # hydra rendereing tool
        "bin/mantra" # mantra renderer
        "houdini/sbin/sesinetd"
      ];
    in
    ''
      mv $out/bin/houdini $out/bin/houdini-wrapper
      WRAPPER=$out/bin/houdini-wrapper
      EXECUTABLES="${lib.concatStringsSep " " executables}"
      for executable in $EXECUTABLES; do
        mkdir -p $out/$(dirname $executable)

        echo "#!${stdenv.shell}" >> $out/$executable
        echo "exec $WRAPPER ${unwrapped}/$executable \"\$@\"" >> $out/$executable
      done

      cd $out
      chmod +x $EXECUTABLES
    '';

  extraBwrapArgs = [
    "--ro-bind-try /run/opengl-driver/etc/OpenCL/vendors /etc/OpenCL/vendors" # this is the case of NixOS
    "--ro-bind-try /etc/OpenCL/vendors /etc/OpenCL/vendors" # this is the case of not NixOS
  ];

  runScript = writeScript "houdini-wrapper" ''
    # ncurses5 is needed by hfs ocl backend
    # workaround for this issue: https://github.com/NixOS/nixpkgs/issues/89769
    export LD_LIBRARY_PATH=${lib.makeLibraryPath [ ncurses5 ]}:$LD_LIBRARY_PATH
    exec "$@"
  '';

  meta = {
    description = "3D animation application software";
    homepage = "https://www.sidefx.com";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "houdini";
    hydraPlatforms = [ ]; # requireFile src's should be excluded
    maintainers = with lib.maintainers; [
      canndrew
      kwohlfahrt
      pedohorse
    ];
  };
}
