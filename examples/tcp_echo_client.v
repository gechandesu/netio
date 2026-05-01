import netio

fn main() {
	// Create new TCP socket.
	mut socket := netio.Socket.new(netio.af_inet, netio.sock_stream, 0) or {
		eprintln('SOCKET: ${err}')
		exit(1)
	}

	// Close socket on exit.
	defer {
		socket.close() or { panic(err) }
	}

	// Create the server socket address.
	server_addr := netio.SocketAddr.new_ipv4([..]u8[127, 0, 0, 1], 1088)

	// Connect socket to the server address.
	socket.connect(server_addr) or {
		eprintln('CONNECT: ${err}')
		exit(1)
	}

	eprintln('Connected to server ${server_addr}...')

	// Send message to the server.
	msg := 'Hello from client!'

	sent := socket.send(msg.bytes(), 0) or {
		eprintln('SEND: ${err}')
		exit(1)
	}

	eprintln('Sent to the server: ${sent} bytes, data: ${msg}')

	// Read the server reply.
	mut buf := []u8{len: 512}

	read := socket.recv(mut buf, 0) or {
		eprintln('RECV: ${err}')
		exit(1)
	}

	if read > 0 {
		eprintln('Received from server: ${read} bytes, data: ${buf.bytestr()}')
	} else if read == 0 {
		eprintln('Server closed the connection.')
	}
}
