{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nixosTests,
  nodejs,
}:
buildNpmPackage rec {
  pname = "immich-public-proxy";
  version = "1.5.3-unstable-2024-12-11";
  src = fetchFromGitHub {
    owner = "alangrainger";
    repo = "immich-public-proxy";
    # 1.5.3 plus upstreamed nixpkgs patches
    rev = "69db5600a0bbcee4ee80d9d863ee27276e3ba9c6";
    hash = "sha256-Hu3CPkyJ9LE6DAwIJ2CNQXNQBUnGiDU/UvOAjZkPFRY";
  };

  sourceRoot = "${src.name}/app";

  npmDepsHash = "sha256-dEdEonVS+NFfov+w/wupTtc55ww9zx61n4qFM29mcUY=";

  # patch in absolute nix store paths so the process doesn't need to cwd in $out
  postPatch = ''
    substituteInPlace src/index.ts --replace-fail \
      "const app = express()" \
      "const app = express()
    // Set the views path to the nix output
    app.set('views', '$out/lib/node_modules/immich-public-proxy/views')" \
    --replace-fail \
      "static('public'" \
      "static('$out/lib/node_modules/immich-public-proxy/public'"
  '';

  passthru.tests = {
    inherit (nixosTests) immich-public-proxy;
  };

  meta = {
    description = "Share your Immich photos and albums in a safe way without exposing your Immich instance to the public";
    homepage = "https://github.com/alangrainger/immich-public-proxy";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ jaculabilis ];
    inherit (nodejs.meta) platforms;
    mainProgram = "immich-public-proxy";
  };
}
