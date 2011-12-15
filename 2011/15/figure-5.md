# Figure 5: wordpress_tarball_is_unrolled bundle

    bundle agent wordpress_tarball_is_unrolled
    {

    classes:
      "wordpress_directory_is_present" expression =>
    fileexists("/var/www/html/wordpress/");

    reports:
      wordpress_directory_is_present::
        "WordPress directory is present.";


    commands:

      !wordpress_directory_is_present::

        "/bin/tar -C /var/www/html -xvzf /root/wordpress-latest.tar.gz"
          comment => "Unrolling wordpress tarball to /var/www/html/.";
    }
