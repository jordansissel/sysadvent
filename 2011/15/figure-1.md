# Figure 1: Control Promise

    #!/var/cfengine/bin/cf-agent -Kif

    body common control 
    {

      bundlesequence => {
            "packages_installed",
            "services_up",
            "wordpress_tarball_is_present",
            "wordpress_tarball_is_unrolled",
            "configuration_of_mysql_db_for_wordpress",
            "wpconfig_exists",
            "wpconfig_is_properly_configured",
            "allow_http_inbound",
            };

      inputs =>	{ "/var/cfengine/inputs/cfengine_stdlib.cf" };

    }
