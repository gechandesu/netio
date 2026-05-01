module netio

/*
	Common constants. Should work on most systems.
*/

pub const af_unspec = AddrFamily(C.AF_UNSPEC)
pub const af_unix = AddrFamily(C.AF_UNIX)
pub const af_inet = AddrFamily(C.AF_INET)
pub const af_inet6 = AddrFamily(C.AF_INET6)

pub const sock_stream = SocketType(C.SOCK_STREAM)
pub const sock_dgram = SocketType(C.SOCK_DGRAM)
pub const sock_seqpacket = SocketType(C.SOCK_SEQPACKET)
pub const sock_raw = SocketType(C.SOCK_RAW)

pub const sol_socket = SocketLevel(C.SOL_SOCKET)
