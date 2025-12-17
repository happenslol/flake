{buildNpmPackage}:
buildNpmPackage {
  name = "npm-global";
  src = ./.;
  npmDepsHash = "sha256-kSKf97dAj6B1JKHHp0L5nerKcK+W6bjmfB51RnTf50E=";
  dontNpmBuild = true;
  postInstall = ''
    mkdir -p $out/bin $out/lib
    cp -r node_modules $out/lib
    ln -s $out/lib/node_modules/.bin/* $out/bin
  '';
}
