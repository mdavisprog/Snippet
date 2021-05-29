# Overview
This document provides a location to place all future tasks.

## v0.2
- [ ] Ability to save snippets. Each snippet should have 2 files. One is SNIPPET_NAME.lua and the other will be SNIPPET_NAME_tests.lua
	- [x] Create workspace option which creates a .snippet folder.
	- [x] App should default to empty temporary workspace.
	- [x] Automatic 'main' snippet created with new workspace.
	- [x] Attempt to load previously saved workspace.
	- [x] Close existing workspace.
	- [x] Open a workspace.
		- [x] Grab all lua files and create a snippet for each file paired with its unit test file.
	- [x] Save snippet graph locations to a GRAPH file. JSON format. For now, just save on exit/close.
	- [x] Prompt developer if they would like to overwrite existing workspace when creating a new workspace.
	- [x] Creating main snippet should create the main.lua and main.unittest.lua.
	- [x] Serialize changes made to snippets when window is closed.
	- [x] Rename snippets if title changes.
	- [ ] Prompt developer if they would like to save changes made to the temporary workspace.
	- [ ] Store workspace translation.
- [ ] BUG: Resizing viewport will resize all FloatingWindow instances.
- [ ] Get working project for Linux.
	- [ ] Compile C++ library for Linux.
	- [ ] Setup export for Linux platform.
- [ ] Change icon.
- [ ] Change splash screen.
- [ ] Change 'File' menu bar icon.
- [ ] Allow unit test to define values used in the snippet.
- [ ] Runtime visualization.
- [ ] Documentation.

## Unsorted
* Left click and drag to make a selection box on the UI layer. After completion, should check to see if any snippets are enclosed in the region's world space.
* Make moving windows transparent. Similar to Kubuntu windows.
* Workspace input should be blocked by snippet windows.
* Dragging off of a connection pin should bring up a context menu. Developer should be able to quickly add a snippet this way.
* Callback support. Developers should be able to call a function called 'callout' which takes a snippet name and some arguments. These callouts will create additional output pins which allows other developers to create a snippet which is called when the 'callout' is called.
* Create a title region on a node for the label.
* Draw bezeir curves between pin connections. These should be drawn in another layer.
* Convert curves to draw textures at a fixed interval.
* Function focus a snippet. Camera should animate towards position.
* Prevent altering Main snippet name and arguments.
	* Could just allow it but throw compile error if 'main' function is not found.
* May need to handle Lua keywords? Better error messages for keywords.
* Only open a small portion of the standard lua libraries.
* Trim available functions in the global namespace.
* Add Success color state for line and status bar.
* Compile time errors should only highlight left margin.
* Quick key to run unit tests.
* Allow any snippet to use any programming language?
* Update to VisualStudio 2019 compiler.
* Snippet database file could be a cached file in a hidden folder. Filename can be relative path from root hash.
* Investigate ways to have snippets return a name with the value so that it can be referenced by that name in the connected snippet.
* Look at different ways to show compile errors instead of in the output window.
	* Could maybe show in a tooltip window. Maybe the autocomplete window?
* Full debugging support.
	* Should be able to set breakpoints.
	* Should be able to inspect all data in each snippet.
* Runtime visualization.
	* Executing snippets should be animated to show snippet was executed.
	* Connections should play an animation when execution has transferred between snippets.
* Networking Support.
	* Host should be able to accept client connections and begin working in the same workspace together.
* Add a 'next' function in the lua global namespace. This will let the application know what the connected snippet is for loading/saving connections.
	* This should be investigative. Might be better to keep this information in a database file inside of the .snippet folder.
* Workspace settings to set name.
