#!/usr/bin/env ruby
# Runs a command with a timeout.
# If the command does not complete within the timeout, we abort and send the
# subproccess SIGTERM.
# 
# Author: Jordan Sissel
# License: BSD

require 'timeout'

if ARGV.length < 2
  STDERR.puts "Usage: #{$0} <timeout> command ..."
  STDERR.puts "  Timeout is in seconds, and can be fractional, ie 3.5"
  exit 1
end

timeout = ARGV[0].to_f
cmd = ARGV[1..-1]

pid = nil
begin
  Timeout.timeout(timeout) do
    pid = fork do
      exec(*cmd);
      exit 1 # in case exec() fails
    end
    Process.waitpid(pid)
    pid = nil
    exit $?.exitstatus
  end
rescue Timeout::Error
  STDERR.puts "#{$0}: Execution expired (timeout == #{timeout})"
  # kill the process if it's still alive.
  if pid
    # Kill child child processes
    system("pkill -TERM -P #{pid}")
    # Now kill the child process
    Process.kill('TERM', pid)
  end
  exit 254
end

