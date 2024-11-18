# Used in the generation of package search database.
{
  # Ensures no aliases are in the results.
  allowAliases = false;

  # Enable recursion into attribute sets that nix-env normally doesn't look into
  # so that we can get a more complete picture of the available packages for the
  # purposes of the index.
  packageOverrides =
    super:
    let
      inherit (builtins) isAttrs mapAttrs tryEval;
      inherit (super) recurseIntoAttrs;
      inherit (super.lib) attrNames;

      passthruAdded = mapAttrs (
        name: value:
        let
          broken = [
            # php shadows overrideAttrs with a function that only accepts (prev: { })
            "php"
            # gnucap uses // to add .withPlugins, which is lost with .overrideAttrs and breaks gnucap-full
            # this could be fixed by moving those to .passthru
            "gnucap"
            # idk why this breaks
            "sbcl"
            "sbcl_2_4_10"
            # appends .bare using // like gnucap, needs that moved to .passthru
            "scala"
            "scala_3"
          ];
          attempt = tryEval value;
        in
        if
          !builtins.elem name broken
          && attempt.success
          && isAttrs attempt.value
          && attempt.value ? "overrideAttrs"
        then
          attempt.value.overrideAttrs (
            final0: prev0: {
              meta = (prev0.meta or { }) // {
                passthru = attrNames (final0.passthru or { });
              };
            }
          )
        else
          value
      ) super;

      packageSetsMarkedForRecursion = mapAttrs (_: set: recurseIntoAttrs set) {
        inherit (super)
          agdaPackages
          apacheHttpdPackages
          fdbPackages
          fusePackages
          gns3Packages
          haskellPackages
          idrisPackages
          nodePackages
          nodePackages_latest
          platformioPackages
          rPackages
          roundcubePlugins
          sourceHanPackages
          ut2004Packages
          zabbix50
          zabbix60
          zeroadPackages
          ;

        # Make sure haskell.compiler is included, so alternative GHC versions show up,
        # but don't add haskell.packages.* since they contain the same packages (at
        # least by name) as haskellPackages.
        haskell = super.haskell // {
          compiler = recurseIntoAttrs super.haskell.compiler;
        };

        # minimal-bootstrap packages aren't used for anything but bootstrapping our
        # stdenv. They should not be used for any other purpose and therefore not
        # show up in search results or repository tracking services that consume our
        # packages.json https://github.com/NixOS/nixpkgs/issues/244966
        minimal-bootstrap = { };
      };
    in
    passthruAdded // packageSetsMarkedForRecursion;
}
