# Figure 2: packages_installed bundle

    bundle agent packages_installed

    {

    vars: "desired_package" slist => {
              "httpd",
              "php",
              "php-mysql",
              "mysql-server",
             };

    packages: "$(desired_package)"
        package_policy => "add",
        package_method => yum,
        classes => if_repaired("packages_added");

    commands:

      packages_added::
      
      "/sbin/service httpd graceful"

        comment => "Restarting httpd so it can pick up new modules.";

    }
