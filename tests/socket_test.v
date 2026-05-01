import netio

fn test_socket_new() {
	socket := netio.Socket.new(netio.af_inet, netio.sock_stream, 0)!
	socket.close() or { panic(err) }
	assert socket.fd != -1
}

fn test_socket_type() {
	socket := netio.Socket.new(netio.af_inet, netio.sock_stream, 0)!
	socket_type := socket.type()!
	socket.close() or { panic(err) }
	assert socket_type == netio.sock_stream
}

fn test_socket_option() {
	mut socket := netio.Socket.new(netio.af_inet, netio.sock_stream, 0)!
	socket.set_option(netio.sol_socket, netio.so_reuseaddr, true)!
	opt_val_int := socket.get_option[int](netio.sol_socket, netio.so_reuseaddr)!
	opt_val_bool := socket.get_option[bool](netio.sol_socket, netio.so_reuseaddr)!
	socket.close() or { panic(err) }
	assert opt_val_int == 1
	assert opt_val_bool == true
}
