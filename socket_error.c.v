module netio

import os

$if windows {
	#flag -lws2_32
	#include <winsock2.h>

	fn C.WSAGetLastError() i32
}

fn last_error() IError {
	$if windows {
		code := int(C.WSAGetLastError())
		return error_with_code(os.get_error_msg(code), code)
	} $else {
		return os.last_error()
	}
}
