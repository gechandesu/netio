import os
import time

fn run(entrypoint string) os.Result {
	cmd := 'v -Wfatal-errors -path "${@VMODROOT}/../|@vlib" run ${entrypoint}'
	return os.execute(cmd)
}

fn test_example_host_fqdn() {
	r := run('examples/host_fqdn.v')
	dump(r.output)
	// host_fqdn may return empty string and this is also fine. So check exit_code only.
	assert r.exit_code == 0
}

fn test_example_tcp_echo_server() {
	expect_server := 'Listening on 127.0.0.1:1088...
	|Accpeted connection. Remote address: 127.0.0.1, remote port: 1001
	|Received from client: 18 bytes, data: Hello from client!
	|Sent to the client: 18 bytes, data: Hello from client!'.strip_margin()

	expect_client := 'Connected to server 127.0.0.1:1088...
	|Sent to the server: 18 bytes, data: Hello from client!
	|Received from server: 18 bytes, data: Hello from client!'.strip_margin()

	mut threads := []thread os.Result{}
	threads << spawn run('examples/tcp_echo_server.v -test')
	time.sleep(time.second * 1)
	threads << spawn run('examples/tcp_echo_client.v')
	results := threads.wait()

	// result.output contains the string with lots of trailing zeros, so we
	// use limit() to shrink the output string to the expected length.
	for result in results {
		dump(result)
		assert result.exit_code == 0
		if result.output.contains('Listening') {
			assert result.output.limit(expect_server.len) == expect_server
		} else {
			assert result.output.limit(expect_client.len) == expect_client
		}
	}
}
