/**

MIT License

Copyright (c) 2022-2023 Mitchell Davis <mdavisprog@gmail.com>

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

#include "OctaneGUI/Controls/Container.h"

namespace OctaneGUI
{
class Application;
class TextEditor;
}

namespace Snippet
{
namespace Controls
{

class Node;

class Document : public OctaneGUI::Container
{
    CLASS(Snippet.Document)

public:
    static void Open(OctaneGUI::Application& App, const std::shared_ptr<Node>& Item);
    static void Close(OctaneGUI::Application& App, const std::shared_ptr<Node>& Item);

    Document(OctaneGUI::Window* Window);

    Document& SetNode(const std::shared_ptr<Node>& Item);
    const std::weak_ptr<Node>& GetNode() const;

private:
    std::shared_ptr<OctaneGUI::TextEditor> m_Editor { nullptr };
    std::weak_ptr<Node> m_Node {};
};

}
}
