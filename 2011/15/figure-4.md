# Figure 4: wordpress_tarball_is_present bundle

    bundle agent wordpress_tarball_is_present
    {

    classes:
      "wordpress_tarball_is_present" expression =>
    fileexists("/root/wordpress-latest.tar.gz");

    reports:
      wordpress_tarball_is_present::
        "WordPress tarball is on disk.";

    commands:
      !wordpress_tarball_is_present::
        "/usr/bin/wget -q -O /root/wordpress-latest.tar.gz
    http://wordpress.org/latest.tar.gz"
        comment => "Downloading WordPress.";
    }
