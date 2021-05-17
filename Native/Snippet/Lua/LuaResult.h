/**

MIT License

Copyright (c) 2021 Mitchell Davis <mdavisprog@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

#pragma once

#include "Godot.hpp"
#include "LuaError.h"
#include "Reference.hpp"

namespace godot
{

class LuaResult : public Reference
{
	GODOT_CLASS(LuaResult, Reference)

public:
	static void _register_methods();

	LuaResult();
	~LuaResult();

	void _init();
	int GetLine() const;
	String GetMessage() const;

	bool Success;
	Array Results;

	// https://github.com/godotengine/godot-cpp/issues/417
	// Reference members unfortunately cannot be exported to script so will need to handle
	// it differently through methods.
	// TODO: Might need to look into serialization if the reference object can't be serialized.
	// e.g. _get_properties_list()
	Ref<LuaError> Error;
};

}
