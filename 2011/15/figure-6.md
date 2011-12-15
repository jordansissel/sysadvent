# Figure 6: configuration_of_mysql_db_for_wordpress bundle

    bundle agent configuration_of_mysql_db_for_wordpress
    {

    commands:
      "/usr/bin/mysql -u root -e \"
        CREATE DATABASE IF NOT EXISTS wordpress;
        GRANT ALL PRIVILEGES ON wordpress.*
        TO 'wordpress'@localhost
        IDENTIFIED BY 'lopsa10linux';
        FLUSH PRIVILEGES;\"
      ";

    }


