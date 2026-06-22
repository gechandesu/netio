import netio
import os

fn main() {
	path := $if windows {
		r'C:\\Temp\dgram_socket_server.sock'
	} $else {
		'/tmp/dgram_socket_server.sock'
	}

	os.rm(path) or {}

	socket_addr := netio.SocketAddr.new_unix(path)!

	mut socket := netio.Socket.new(socket_addr.family(), netio.sock_dgram, 0) or {
		eprintln('SOCKET: ${err}')
		exit(1)
	}

	defer {
		socket.close() or {}
		os.rm(path) or {}
	}

	socket.bind(socket_addr)!

	println('Listening on ${path}...')

	mut buf := []u8{len: 1024}
	for {
		n := socket.recv(mut buf, 0) or {
			eprintln('RECV: ${err}')
			exit(1)
		}
		if n == 0 {
			continue
		}
		data := buf[..n].clone()
		if data == 'quit'.bytes() {
			break
		}
		println('Data received (${n} bytes): ${data.bytestr()}')
	}
}
