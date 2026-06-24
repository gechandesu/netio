import netio

/*
	This program starts a server that listens for TCP connections on port 1081.
	The program listens on all addresses available in the operating system,
	including IPv4 and IPv6.

	Run the program and try connecting using the telnet utility:

		telnet 127.0.0.1 1088   # IPv4
		telnet ::1 1088         # IPv6

	This program fails if operation system does not support IPv6 or IPv6 is disabled.
*/

fn main() {
	// We want to bind a server socket to the all available local addresses,
	// (both IPv4 and IPv6) so collect the address info entries for it.
	ai := netio.addr_info(
		service:  '1088'            // The port number to listen.
		socktype: netio.sock_stream // Address must support TCP transport.
		family:   netio.af_inet6    // IPv6 support.
		flags:    netio.ai_passive  // Passive mode for binding to any address (0.0.0.0, ::).
	)!

	// Just initialize variables.
	mut socket := netio.Socket{}
	mut listen_addr := netio.SocketAddr{}

	// Create socket and bind to the first available address.
	for a in ai {
		// Create a socket with advertised parameters.
		socket = netio.Socket.new(a.family, a.socktype, a.protocol)!

		// Set SO_REUSEADDR enabled. It allows a server to bind to a port that
		// is still in a `TIME-WAIT` state from a previous connection.
		// https://en.wikipedia.org/wiki/Transmission_Control_Protocol#Protocol_operation
		socket.set_option(netio.sol_socket, netio.so_reuseaddr, 1)!

		// Allow connections through IPv4, not only IPv6.
		socket.set_option(netio.ipproto_ipv6, netio.ipv6_v6only, 0)!

		// Bind socket to the address.
		socket.bind(a.addr) or {
			// Close previously created socket on bind error and continue with
			// the next socket address.
			socket.close()!
			continue
		}
		// Set listen_addr.
		listen_addr = a.addr
		break
	}

	// If the socket.fd is -1 this means that we does not find any socket address.
	if socket.fd == -1 {
		eprintln('Cannot create socket...')
		exit(1)
	}

	// Close the server socket on exit.
	defer {
		socket.close() or { panic(err) }
	}

	// Start listening for incoming connections on socket.
	socket.listen(10) or {
		eprintln('LISTEN: ${err}')
		exit(1)
	}

	println('Listening on ${listen_addr}...')

	for {
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
		remote_host, remote_port := netio.name_info(remote_addr,
			flags: netio.ni_numerichost | netio.ni_numericserv
		)!

		eprintln('Accepted connection. Remote address: ${remote_host}, remote port: ${remote_port}')

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
		$if netio_test ? {
			conn.send(msg.bytes(), 0) or {
				eprintln('SEND: ${err}')
				exit(1)
			}
			break
		}
	}
}
