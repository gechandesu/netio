import netio
import os

fn test_unix_socket() {
	mut socket := netio.Socket.new(netio.af_unix, netio.sock_stream, 0)!
	addr := $if windows {
		r'C:\\Temp\netio-test-unix.sock'
	} $else {
		'/tmp/netio-test-unix.sock'
	}
	os.rm(addr) or {}
	socket_addr := netio.SocketAddr.new_unix(addr)!
	socket.bind(socket_addr)!
	socket.close()!
}
