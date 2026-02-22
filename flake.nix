{
  description = "Centralized development shells for all project types";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };

          # ============== SHARED BASICS ==============
          basics = with pkgs; [
            git
            curl
            jq
          ];

          # ============== NODE.JS SHELL ==============
          nodejsShell = pkgs.mkShell {
            name = "nodejs-devshell";

            packages =
              with pkgs;
              [
                nodejs
                corepack
                openssl
              ]
              ++ basics;

            nativeBuildInputs = with pkgs; [
              python3
              pkg-config
              gcc
              gnumake
            ];

            shellHook = ''
              export PATH="$PWD/node_modules/.bin:$PATH"

              mkdir -p .idea/sdk
              ln -sf ${pkgs.nodejs}/bin/node .idea/sdk/node
              ln -sf ${pkgs.nodejs}/bin/npm  .idea/sdk/npm
              ln -sf ${pkgs.nodejs}/bin/npx  .idea/sdk/npx

              if command -v corepack >/dev/null 2>&1; then
                corepack enable >/dev/null 2>&1 || true
              fi

              export NODE_ENV=development

              echo "✅ Node.js dev shell ready ($(node --version))"
            '';
          };

          # ============== KOTLIN MULTIPLATFORM SHELL ==============
          kotlinShell =
            let
              jdk = pkgs.jetbrains.jdk;
              gradle = pkgs.gradle;
              chromium = pkgs.chromium;

              libPath = pkgs.lib.makeLibraryPath (
                with pkgs;
                [
                  nodejs
                  libglvnd
                  libGLU
                  mesa
                  libx11
                  libxext
                  libxi
                  libxrender
                  libxtst
                  libxxf86vm
                  libxcursor
                  libxrandr
                  fontconfig
                  freetype
                  zlib
                  stdenv.cc.cc.lib
                ]
              );
            in
            pkgs.mkShell {
              name = "kotlin-multiplatform-shell";

              packages = [
                jdk
                gradle
                chromium
              ]
              ++ basics;

              shellHook = ''
                export LD_LIBRARY_PATH="${libPath}:$LD_LIBRARY_PATH"
                export JAVA_HOME="${jdk}"
                export GRADLE_OPTS="-Dorg.gradle.java.home=${jdk}"
                export CHROME_BIN="${chromium}/bin/chromium"
                export PATH="$PWD/.idea/sdk/bin:$PATH"

                mkdir -p .idea/sdk/bin
                ln -sfT "${chromium}" .idea/sdk/chromium-home
                ln -sfT "${jdk}" .idea/sdk/jdk-home
                ln -sfT "${gradle}" .idea/sdk/gradle-home
                ln -sf ${pkgs.nodejs}/bin/node .idea/sdk/bin/node
                ln -sf ${pkgs.nodejs}/bin/npm  .idea/sdk/bin/npm
                ln -sf ${pkgs.nodejs}/bin/npx  .idea/sdk/bin/npx
                ln -sf "${jdk}/bin/java"      .idea/sdk/bin/java
                ln -sf "${gradle}/bin/gradle" .idea/sdk/bin/gradle
                ln -sf "${chromium}/bin/chromium" .idea/sdk/bin/chromium

                echo "✅ Kotlin Multiplatform shell ready"
                echo "   Java:   $(java --version 2>&1 | head -n1)"
                echo "   Gradle: $(gradle --version | grep Gradle)"
                echo "   Kotlin: Managed by Gradle (check gradle/libs.versions.toml)"
              '';
            };

          # ============== PYTHON SHELL (example for future) ==============
          pythonShell = pkgs.mkShell {
            name = "python-devshell";
            packages =
              with pkgs;
              [
                python312
                poetry
              ]
              ++ basics;
            shellHook = ''
              echo "✅ Python dev shell ready ($(python --version))"
            '';
          };


          # ============== Java And Maven SHELL ==============
          javaShell =
            let
              jdk = pkgs.jetbrains.jdk;
              gradle = pkgs.gradle;
              maven = pkgs.maven;

              libPath = pkgs.lib.makeLibraryPath (
                with pkgs;
                [
                  libglvnd
                  libGLU
                  mesa
                  libx11
                  libxext
                  libxi
                  libxrender
                  libxtst
                  libxxf86vm
                  libxcursor
                  libxrandr
                  fontconfig
                  freetype
                  zlib
                  stdenv.cc.cc.lib
                ]
              );
            in
            pkgs.mkShell {
              name = "java-shell";

              packages = [
                jdk
                gradle
                maven
              ]
              ++ basics;

              shellHook = ''
                export LD_LIBRARY_PATH="${libPath}:$LD_LIBRARY_PATH"
                export JAVA_HOME="${jdk}"
                export GRADLE_OPTS="-Dorg.gradle.java.home=${jdk}"
                export MAVEN_HOME="${maven}"
                export PATH="$PWD/.idea/sdk/bin:$PATH"

                mkdir -p .idea/sdk/bin
                ln -sfT "${maven}" .idea/sdk/maven-home
                ln -sfT "${jdk}" .idea/sdk/jdk-home
                ln -sfT "${gradle}" .idea/sdk/gradle-home
                ln -sf ${pkgs.nodejs}/bin/node .idea/sdk/bin/node
                ln -sf ${pkgs.nodejs}/bin/npm  .idea/sdk/bin/npm
                ln -sf ${pkgs.nodejs}/bin/npx  .idea/sdk/bin/npx
                ln -sf "${jdk}/bin/java"      .idea/sdk/bin/java
                ln -sf "${gradle}/bin/gradle" .idea/sdk/bin/gradle
                ln -sf "${maven}/bin/mvn" .idea/sdk/bin/mvn

                echo "✅ Java and Maven shell ready"
                echo "   Java:   $(java --version 2>&1 | head -n1)"
                echo "   Gradle: $(gradle --version | grep Gradle)"
                echo "   Maven:  $(mvn --version | head -n1)"
              '';
            };

          


        in
        {
          # Named shells
          nodejs = nodejsShell;
          kotlin = kotlinShell;
          python = pythonShell;
          java = javaShell;

          # Default shell (pick your most common one)
          default = nodejsShell;
        }
      );
    };
}
