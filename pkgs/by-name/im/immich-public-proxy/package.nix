{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs,
}:
let
  pname = "immich-public-proxy";
  version = "1.5.2";
  repo = fetchFromGitHub {
    owner = "alangrainger";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-0X/cOs5vFL/7LZYl+eZ3XWtNfggCqHBa9K/xbz5bdYY=";
  };
in
buildNpmPackage {
  inherit pname version;
  src = "${repo}/app";

  # -p2 is needed to strip the app/ prefix on the file paths, since it's already accounted for by src above
  patchFlags = "-p2";
  patches = [
    # allow binding to ports other than 3000 via IPP_PORT envvar
    ./0001-Make-port-configurable-via-IPP_PORT.patch
    # add a bin output to package.json so we get a binary output
    ./0002-Add-bin-to-package.json.patch
  ];

  # use generated package-lock.json as upstream does not provide one
  postPatch = ''
    cp ${./package-lock.json} ./package-lock.json
  '';

  npmDepsHash = "sha256-R3Y3F6NnaSyWwMdV2dwCC9O82ENBWNPl0wJqSDRGF2Q=";

  # patch in absolute nix store paths so the process doesn't need to cwd in $out
  postInstall = ''
    sed -i "/const app =/a // Set the views path to the nix output\napp.set('views', '$out/lib/node_modules/immich-public-proxy/views')" \
      $out/lib/node_modules/immich-public-proxy/dist/index.js
    substituteInPlace $out/lib/node_modules/immich-public-proxy/dist/index.js --replace-warn \
      "static('public'" \
      "static('$out/lib/node_modules/immich-public-proxy/public'"
  '';

  meta = {
    description = "Share your Immich photos and albums in a safe way without exposing your Immich instance to the public.";
    homepage = "https://github.com/alangrainger/immich-public-proxy";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ jaculabilis ];
    inherit (nodejs.meta) platforms;
    mainProgram = "immich-public-proxy";
  };
}
