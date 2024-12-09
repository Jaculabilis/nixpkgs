{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs,
}:
buildNpmPackage rec {
  pname = "immich-public-proxy";
  version = "1.5.3-unstable-2024-12-02";
  src = fetchFromGitHub {
    owner = "alangrainger";
    repo = "immich-public-proxy";
    # 1.5.3 plus upstreamed nixpkgs patches
    rev = "e4d66a5cccf67bb9c3cf7939b39c4569ba064b35";
    hash = "sha256-VClwkhuvp6gZNZaTp7gqjHy+4uiGJPJFF/1/Sb4KCRw=";
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

  meta = {
    description = "Share your Immich photos and albums in a safe way without exposing your Immich instance to the public";
    homepage = "https://github.com/alangrainger/immich-public-proxy";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ jaculabilis ];
    inherit (nodejs.meta) platforms;
    mainProgram = "immich-public-proxy";
  };
}
