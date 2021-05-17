# Overview
This document provides a location to place all future tasks.

## v0.1
[x] Global output window to display any output and status messages.
[ ] Separate 'Run' button for running all connected snippets vs unit test.
[x] Default maximize on startup.
[ ] Ability to save snippets. Each snippet should have 2 files. One is SNIPPET_NAME.lua and the other will be SNIPPET_NAME_tests.lua
[ ] Refocus opened snippet editor for same snippets. Prevent duplicate snippet editors for the same snippet.
[ ] Add tooltips for snippet window buttons.
[ ] Print runtime stack trace to output window.

### connected_snippets
[x] Provide a separate run button for running whole program vs unit test.
[ ] Investigate the need to pass Lua states between snippets.
[ ] Investigate passing return values from a snippet to the next snippet.
[ ] Should translated snippet code be stored?
[ ] Should snippet function be placed in a table?
[ ] Move parse result to a cached variable.
[ ] Disable 'Run unit tests' button if snippet cache is invalid or error.
[ ] 'CallExpanded' function which accepts an array and pushes each element as each individual parameter instead of a table.

### Items

## Unsorted
* Left click and drag to make a selection box on the UI layer. After completion, should check to see if any snippets are enclosed in the region's world space.
* Make moving windows transparent. Similar to Kubuntu windows.
* Rework 'File' menu image. Edges and corners of fold should match standard corner.
	* Should also convert to a single image with two states like the close button to reduce need for custom code logic.
* Workspace input should be blocked by snippet windows.
* Compile C++ library for Linux.
* Get working project for Linux.
* Add connection pins for snippets that dictate the logical flow of a program. When a snippet is connected, the return values of the previous snippet should be passed as the last arguments of the connected snippet.
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
