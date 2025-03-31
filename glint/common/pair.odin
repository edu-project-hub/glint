package common

Pair :: struct($T: typeid) {
	first:  T,
	second: T,
}

pair_init :: proc($T: typeid, v1, v2: T) -> Pair(T) {
	return Pair{first = v1, second = v2}
}

