# Figure 3: services_up bundle

    bundle agent services_up {

    processes:
      "^mysqld" restart_class => "start_mysqld";
      "^httpd"  restart_class => "start_httpd";

    commands:

      start_mysqld::

      "/sbin/service mysqld start";

      start_httpd::

      "/sbin/service httpd start";

    }

