#pragma once

#include "godot_cpp/variant/vector3.hpp"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

//Define your class for the space mouse
class SpacemouseDevice : public godot::Object {
	GDCLASS(SpacemouseDevice, godot::Object)

public:
	SpacemouseDevice();
	~SpacemouseDevice();

	bool connect();
	bool disconnect();
	godot::Vector3 get_translation();
	godot::Vector3 get_rotation();
	bool is_modified() const;
	int get_buttons() const;
	bool get_debug() const;
	void set_debug(bool value);

	// hack since we can't use instance callbacks
	static SpacemouseDevice *connected_device;
	void messageHandler(unsigned int productID, unsigned int messageType, void *messageArgument);
	void mouseAdded(unsigned int productID);
	void mouseRemoved(unsigned int productID);

protected:
	static void _bind_methods();

private:

	// current connection
	uint16_t connexionClientID;

	godot::Vector3 translation;
	godot::Vector3 rotation;
	bool modified = false;
	bool debug = false;
	uint16_t buttons = 0;
};
