# Overview
This document provides a location to place all future tasks.

# v0.3
- [x] About page.
- [ ] Debugger.
- [ ] Launch in separate process.
- [ ] Socket communication for debugging.

## Unsorted
* Left click and drag to make a selection box on the UI layer. After completion, should check to see if any snippets are enclosed in the region's world space.
* Make moving windows transparent. Similar to Kubuntu windows.
* Workspace input should be blocked by snippet windows.
* Dragging off of a connection pin should bring up a context menu. Developer should be able to quickly add a snippet this way.
* Callback support. Developers should be able to call a function called 'callout' which takes a snippet name and some arguments. These callouts will create additional output pins which allows other developers to create a snippet which is called when the 'callout' is called.
* Function focus a snippet. Camera should animate towards position.
* Only open a small portion of the standard lua libraries.
* Trim available functions in the global Lua namespace.
* Add Success color state for line and status bar.
* Compile time errors should only highlight left margin.
* Quick key to run unit tests.
* Allow any snippet to use any programming language?
* Update to VisualStudio 2019 compiler.
* Investigate ways to have snippets return a name with the value so that it can be referenced by that name in the connected snippet.
* Full debugging support.
	* Should be able to set breakpoints.
	* Should be able to inspect all data in each snippet.
* Networking Support.
	* Host should be able to accept client connections and begin working in the same workspace together.
* Add a 'next' function in the lua global namespace. This will let the application know what the connected snippet is for loading/saving connections.
	* This should be investigative. Might be better to keep this information in a database file inside of the .snippet folder.
* Workspace settings to set name.
* BUG: Resizing viewport will resize all FloatingWindow instances.
* BUG: Curve control points not properly aligned when modifying an output connection.
* Allow unit test to define values used in the snippet.
* Maybe have function inheritance?
