{buildNpmPackage}:
buildNpmPackage {
  name = "npm-global";
  src = ./.;
  npmDepsHash = "sha256-yN50acJxJR8RsOzFaMsYDF+KvTfQAcycOlk5Dhq1Hu4=";
  dontNpmBuild = true;
  postInstall = ''
    mkdir -p $out/bin $out/lib
    cp -r node_modules $out/lib
    ln -s $out/lib/node_modules/.bin/* $out/bin
  '';
}
