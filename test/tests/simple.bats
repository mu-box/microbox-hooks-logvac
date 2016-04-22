# source docker helpers
. util/docker.sh

# source mist helpers
. util/mist.sh

@test "Start Mist Container" {
  start_mist
}

@test "Start Container" {
  start_container "test-single" "192.168.0.2"
}

@test "Configure" {
  # Run Hook
  run run_hook "test-single" "configure" "$(payload configure)"
  [ "$status" -eq 0 ]

  # Verify logvac configuration
  run docker exec test-single bash -c "[ -f /etc/logvac/config.json ]"
  [ "$status" -eq 0 ]

  # Verify narc configuration
  run docker exec test-single bash -c "[ -f /opt/gonano/etc/narc.conf ]"
  [ "$status" -eq 0 ]
}

@test "Start" {
  # Run hook
  run run_hook "test-single" "start" "$(payload start)"
  [ "$status" -eq 0 ]

  # Verify logvac running
  run docker exec test-single bash -c "ps aux | grep [l]ogvac"
  [ "$status" -eq 0 ]

  # Verify narc running
  run docker exec test-single bash -c "ps aux | grep [n]arc"
  [ "$status" -eq 0 ]
}

@test "Verify Service" {
  # Add a log entry
  run docker exec "test-single" bash -c "curl -k https://127.0.0.1:6361 -i -H \"X-AUTH-TOKEN: 123\" -d '{\"id\":\"log-test\",\"type\":\"test\",\"message\":\"my first log\"}'"
  echo "$output"
  [ "$status" -eq 0 ]

  # fetch the log
  run docker exec "test-single" bash -c "curl -k -H \"X-AUTH-TOKEN: 123\" \"https://127.0.0.1:6361?type=test\" 2> /dev/null | grep log-test"
  echo "$output"
  [ "$status" -eq 0 ]
}

@test "Stop" {
  # Run hook
  run run_hook "test-single" "stop" "$(payload start)"
  [ "$status" -eq 0 ]

  # Wait until services shut down
  while docker exec "test-single" bash -c "ps aux | grep [l]ogvac"
  do
    sleep 1
  done

  # Verify logvac is not running
  run docker exec test-single bash -c "ps aux | grep [l]ogvac"
  [ "$status" -eq 1 ]

  # Verify narc is not running
  run docker exec test-single bash -c "ps aux | grep [n]arc"
  [ "$status" -eq 1 ]
}

@test "Stop Container" {
  stop_container "test-single"
}

@test "Stop Mist Container" {
  stop_mist
}
