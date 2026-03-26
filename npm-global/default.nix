{buildNpmPackage}:
buildNpmPackage {
  name = "npm-global";
  src = ./.;
  npmDepsHash = "sha256-Bfh++syCQsblkzHOv7fUrCgZNuxDjOUC7DJJHfxVTwk=";
  dontNpmBuild = true;
  postInstall = ''
    mkdir -p $out/bin $out/lib
    cp -r node_modules $out/lib
    ln -s $out/lib/node_modules/.bin/* $out/bin
  '';
}
