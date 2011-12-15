# Figure 9: allow_http_inbound

    bundle agent allow_http_inbound
    {
    files:
      redhat::  # tested on RHEL only, file location may vary on other OSs
      "/etc/sysconfig/iptables"
        edit_line =>
    insert_HTTP_allow_rule_before_the_accept_established_tcp_conns_rule,
        comment => "insert HTTP allow rule into
    /etc/sysconfig/iptables",
        classes => if_repaired("iptables_edited");

    commands:
      iptables_edited::
      "/sbin/service iptables restart"
        comment => "Restarting iptables to load new config";

    }

    bundle edit_line insert_HTTP_allow_rule_before_the_accept_established_tcp_conns_rule
    {

    vars:
      "http_rule" string => "-A INPUT -p tcp -m tcp --dport 80 -j ACCEPT";

    insert_lines: "$(http_rule)",
      location => before_the_accept_established_tcp_conns_rule;
    }

    body location before_the_accept_established_tcp_conns_rule
    {
    before_after => "before";
    first_last => "first";
    select_line_matching => "^-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT.*";
    }
