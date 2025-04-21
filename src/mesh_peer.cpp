#include "mesh_peer.h"

#include <godot_cpp/classes/e_net_connection.hpp>
#include <godot_cpp/classes/e_net_multiplayer_peer.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/templates/hash_map.hpp>
#include <godot_cpp/variant/string.hpp>

using namespace godot;

void MeshPeer::_bind_methods() {
	ClassDB::bind_static_method("MeshPeer", D_METHOD("get_base_port"), &MeshPeer::get_base_port);
}

MeshPeer::MeshPeer() :
		is_host(true), pending_peer_map(), local_peer(memnew(ENetMultiplayerPeer)) {}

MeshPeer::MeshPeer(HashMap<int, String> peer_map) :
		is_host(false), pending_peer_map(), local_peer(memnew(ENetMultiplayerPeer)) {
	// TODO: create mesh from peer_map
}

void MeshPeer::_process(double delta) {
}

uint16_t MeshPeer::get_base_port() {
	return MeshPeer::BASE_PORT;
}
