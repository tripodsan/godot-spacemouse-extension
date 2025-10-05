#pragma once

#include <godot_cpp/core/class_db.hpp>

#include "godot_cpp/classes/wrapped.hpp"
#include "godot_cpp/variant/variant.hpp"
#include "godot_cpp/variant/vector3.hpp"

#include <godot_cpp/variant/callable_custom.hpp>

using namespace godot;

//Define your class for the space mouse
class SpacemouseDevice : public godot::Object {
	GDCLASS(SpacemouseDevice, godot::Object)
public:
	// typedef struct SpaceData {
	// 	int px, py, pz, rx, ry, rz;
	// } SpaceData;

	// Constructor and destructor
	SpacemouseDevice();
	~SpacemouseDevice();
	bool spacemouse_connect();
	bool spacemouse_disconnect();
	godot::Vector3 spacemouse_translation();
	godot::Vector3 spacemouse_rotation();
	bool get_modified();

	// current connection
	uint16_t connexionClientID;

	// hack since we can't use instance callbacks
	static SpacemouseDevice* connected_device;

	// callbacks
	void messageHandler(unsigned int productID, unsigned int messageType, void *messageArgument);
	void mouseAdded(unsigned int productID);
	void mouseRemoved(unsigned int productID);

protected:
	static void _bind_methods();

private:
	godot::Vector3 translation;
	godot::Vector3 rotation;
	bool modified = false;
};

