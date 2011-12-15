# Figure 7: wpconfig_exists bundle

    bundle agent wpconfig_exists
    {

    classes:
      "wordpress_config_file_exists"
      expression => fileexists("/var/www/html/wordpress/wp-config.php");

    reports:
      wordpress_config_file_exists::
        "WordPress config file /var/www/html/wordpress/wp-config.php is present";

    commands:
      !wordpress_config_file_exists::
      "/bin/cp -p /var/www/html/wordpress/wp-config-sample.php \
        /var/www/html/wordpress/wp-config.php"
        comment => "Creating wp-config.php from wp-config-sample.php";

    }
