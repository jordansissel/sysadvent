# Figure 8: wp_config_is_properly_configured

    bundle agent wpconfig_is_properly_configured
    {
    files:
      "/var/www/html/wordpress/wp-config.php"
        edit_line => replace_default_wordpress_config_with_ours;
    }

    bundle edit_line replace_default_wordpress_config_with_ours
    {
    replace_patterns:
      "database_name_here" replace_with => value("wordpress");

    replace_patterns:
      "username_here" replace_with => value("wordpress");

    replace_patterns:
      "password_here" replace_with => value("lopsa10linux");
    }
