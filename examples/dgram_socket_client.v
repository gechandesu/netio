import netio

fn main() {
	path := $if windows {
		r'C:\\Temp\dgram_socket_server.sock'
	} $else {
		'/tmp/dgram_socket_server.sock'
	}

	socket_addr := netio.SocketAddr.new_unix(path)!

	mut socket := netio.Socket.new(socket_addr.family(), netio.sock_dgram, 0) or {
		eprintln('SOCKET: ${err}')
		exit(1)
	}

	defer {
		socket.close() or {}
	}

	println('Sending data to ${path}...')

	data := ['hello', 'world', 'over', 'dgram', 'unix', 'socket', 'quit']
	for msg in data {
		n := socket.send_to(msg.bytes(), socket_addr, 0) or {
			eprintln('SEND: ${err}')
			exit(1)
		}
		println('Sent ${n} bytes')
	}
}
