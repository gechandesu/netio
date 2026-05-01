import netio

fn main() {
	// This is only for examples_test.v
	is_test := '-test' in arguments()

	// Create listen address.
	listen_addr := netio.SocketAddr.new_ipv4([..]u8[127, 0, 0, 1], 1088)

	// Create server socket.
	socket := netio.Socket.new(netio.af_inet, netio.sock_stream, 0) or {
		eprintln('SOCKET: ${err}')
		exit(1)
	}

	// Close server socket on exit.
	defer {
		socket.close() or { panic(err) }
	}

	// Set SO_REUSEADDR enabled. It allows a server to bind to a port that
	// is still in a `TIME-WAIT` state from a previous connection.
	// https://en.wikipedia.org/wiki/Transmission_Control_Protocol#Protocol_operation
	socket.set_option(netio.sol_socket, netio.so_reuseaddr, 1)!

	// Bind socket to the address.
	socket.bind(listen_addr) or {
		eprintln('BIND: ${err}')
		exit(1)
	}

	// Start listening for incoming connections on socket.
	socket.listen(10) or {
		eprintln('LISTEN: ${err}')
		exit(1)
	}

	println('Listening on ${listen_addr}...')

	// Accept the connection from remote. This is a blocking call.
	// conn will store the new socket connected to the remote.
	conn, remote_addr := socket.accept() or {
		eprintln('ACCEPT: ${err}')
		exit(1)
	}

	// Close connection on exit.
	defer {
		conn.close() or { panic(err) }
	}

	// Get remote host and port in numeric format.
	remote_host, mut remote_port := netio.name_info(remote_addr,
		flags: netio.ni_numerichost | netio.ni_numericserv
	)!

	if is_test {
		remote_port = '1001'
	}
	eprintln('Accpeted connection. Remote address: ${remote_host}, remote port: ${remote_port}')

	// Read 512 bytes of data from socket.
	mut buf := []u8{len: 512} // Initialize the buffer to store message.
	// Receive data and write it to the buffer.
	read := conn.recv(mut buf, 0) or {
		eprintln('RECV: ${err}')
		exit(1)
	}

	// Create a string from buffer without the trailing zeros.
	msg := unsafe { tos_clone(buf.data) }

	eprintln('Received from client: ${read} bytes, data: ${msg}')

	// Send reply to the client.
	sent := conn.send(msg.bytes(), 0) or {
		eprintln('SEND: ${err}')
		exit(1)
	}

	eprintln('Sent to the client: ${sent} bytes, data: ${msg}')
}
