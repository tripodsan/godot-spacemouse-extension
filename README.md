## Godot Space Navigator (Godot 4 Plugin) 🚀

This is a Godot Engine 4.x editor plugin that adds native support for **3Dconnexion Space Mouse** devices, enabling **6 Degrees of Freedom (6DOF)** control over the 3D viewport camera.

---

## ✨ Features

* **6DOF Navigation:** Enjoy precise, simultaneous translation and rotation control over the 3D editor camera.
* **Direct Driver Interaction:** Unlike other solutions, this plugin interacts directly with the **3Dconnexion drivers**, cooperatively working with other plugins.
* **Two Navigation Modes:**
  * **Camera Mode:** Moves the editor camera freely within the 3D space (default Godot navigation style).
  * **Object Mode:** Orbits the camera around the currently **selected node** in the scene.
* **Godot 4.2+ Compatible**

---

## 🛠️ Requirements

To use this plugin, you'll need:

1.  **Godot Engine 4.2 or later** (tested with 4.5).
2.  An installed **3Dconnexion Space Mouse** device (e.g., SpaceNavigator, SpaceMouse Pro, etc.).
3.  The official **3Dconnexion Space Mouse drivers** must be installed and running on your system.

**⚠️ Current Platform Limitation**

* Currently, this plugin is **only supported on macOS**. Support for Windows and Linux may be added in future updates.

---

## 💻 Installation

1.  **Clone or Download:** Get the contents of this repository.
2.  **Move to Project:** Copy the `addons/spacemouse` folder into the `addons/` directory of your Godot project.
3.  **Enable Plugin:**
  * Open your Godot project.
  * Go to **Project -> Project Settings...**
  * Navigate to the **Plugins** tab.
  * Find **"Godot Space Mouse"** and ensure its status is set to **"Enable"**.

## ⚙️ Usage

Once the plugin is enabled, the Space Mouse should automatically begin controlling the 3D viewport camera when the Godot editor is in focus.

### Basic Control

| Action | Space Mouse Control |
| :--- | :--- |
| **6DOF Movement** | The **Controller Cap** (simultaneous translation and rotation) |
| **Recenter/View** | **Button 1** |
| **Toggle Mode** | **Button 2** |

### Button Functionality

* **Button 1 (Recenter/View):**
  * No node selected: Instantly resets the editor camera to the world **origin** (0, 0, 0).
  * Node selected: Frames the camera to a good viewing distance **in front of the currently selected node**.
* **Button 2 (Toggle Mode):** Toggles the navigation mode between **Camera Mode** and **Object Mode**.

### Switching Modes

You can switch between **Camera Mode** and **Object Mode** using **Button 2**.

* **Camera Mode (Default):** Ideal for general scene traversal and exploration.
* **Object Mode:** Perfect for detailed inspection of a specific model or node. Control centers the navigation around the selected object.

---

## 🤝 Contributing

Contributions are welcome! If you find a bug or have an idea for an improvement (especially for Windows/Linux driver interaction), please open an issue or submit a pull request.

---

## 📄 License

This project is licensed under the MIT License - see the `LICENSE` file for details.
