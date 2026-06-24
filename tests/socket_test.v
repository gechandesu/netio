import netio
import time

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
	socket.close()!
	assert opt_val_int == 1
	assert opt_val_bool == true
}

fn tcp_server() {
	mut server := netio.Socket.new(netio.af_inet, netio.sock_stream, 0) or { panic(err) }
	server.set_option(netio.sol_socket, netio.so_reuseaddr, true) or { panic(err) }
	listen_addr := netio.SocketAddr.new_ipv4([u8(127), 0, 0, 1]!, 11089)
	server.bind(listen_addr) or { panic(err) }
	server.listen(1) or { panic(err) }

	conn, remote_addr := server.accept() or { panic(err) }
	assert remote_addr.str().starts_with('127.0.0.1:')

	mut buf := []u8{len: 64}
	read := conn.recv(mut buf, 0) or { panic(err) }
	assert read == 5
	assert buf[..read].bytestr() == 'hello'

	conn.send('world'.bytes(), 0) or { panic(err) }
	conn.shutdown(netio.Shutdown.read_and_write) or { panic(err) }
	conn.close() or { panic(err) }

	mut peer_addr := unsafe { netio.SocketAddr.new(netio.af_unspec, sizeof(netio.SocketAddrStorage)) }
	conn2 := server.accept_addr(mut peer_addr) or { panic(err) }
	assert peer_addr.str().starts_with('127.0.0.1:')
	conn2.close() or { panic(err) }

	conn3 := server.accept_no_addr() or { panic(err) }
	conn3.close() or { panic(err) }

	server.close() or { panic(err) }
}

fn tcp_client() {
	time.sleep(time.millisecond * 200)
	mut client := netio.Socket.new(netio.af_inet, netio.sock_stream, 0) or { panic(err) }
	server_addr := netio.SocketAddr.new_ipv4([u8(127), 0, 0, 1]!, 11089)
	client.connect(server_addr) or { panic(err) }

	client.send('hello'.bytes(), 0) or { panic(err) }

	mut buf := []u8{len: 64}
	read := client.recv(mut buf, 0) or { panic(err) }
	assert read == 5
	assert buf[..read].bytestr() == 'world'

	client.shutdown(netio.Shutdown.write) or { panic(err) }
	client.close() or { panic(err) }

	for _ in 0 .. 2 {
		mut c := netio.Socket.new(netio.af_inet, netio.sock_stream, 0) or { panic(err) }
		c.connect(server_addr) or { panic(err) }
		c.close() or { panic(err) }
	}
}

fn test_socket_tcp() {
	spawn tcp_server()
	time.sleep(time.millisecond * 200)
	tcp_client()
	time.sleep(time.second * 2)
}

$if !windows {
	fn test_socket_send_to_recv_from() {
		mut server := netio.Socket.new(netio.af_inet, netio.sock_dgram, 0)!
		server.set_option(netio.sol_socket, netio.so_reuseaddr, true)!
		server_addr := netio.SocketAddr.new_ipv4([u8(127), 0, 0, 1]!, 11090)
		server.bind(server_addr)!

		mut client := netio.Socket.new(netio.af_inet, netio.sock_dgram, 0)!

		sent := client.send_to('ping'.bytes(), server_addr, 0)!
		assert sent == 4

		mut buf := []u8{len: 64}
		n, peer := server.recv_from(mut buf, 0)!
		assert n == 4
		assert buf[..n].bytestr() == 'ping'
		assert peer.str().starts_with('127.0.0.1:')

		client.close()!
		server.close()!
	}
}
