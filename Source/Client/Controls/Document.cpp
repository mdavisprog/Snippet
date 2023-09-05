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

#include "Document.h"
#include "Node.h"
#include "OctaneGUI/OctaneGUI.h"

namespace Snippet
{
namespace Controls
{

static std::string GetWindowID(const std::shared_ptr<Node>& Item)
{
    std::string Result { "Snippet." };

    if (Item != nullptr)
    {
        Result += OctaneGUI::String::ToMultiByte(Item->Name());
    }

    return Result;
}

void Document::Open(OctaneGUI::Application& App, const std::shared_ptr<Node>& Item)
{
    if (Item == nullptr)
    {
        return;
    }

    const std::string Title { OctaneGUI::String::ToMultiByte(Item->Name()) };
    const std::string WindowID { GetWindowID(Item) };

    if (!App.HasWindow(WindowID.c_str()))
    {
        const std::shared_ptr<OctaneGUI::Window> Window { App.NewWindow(WindowID.c_str(), "{}") };
        Window->SetTitle(Title.c_str());

        const std::shared_ptr<Document> Document_ = Window->GetContainer()->AddControl<Document>();
        Document_->SetNode(Item);
    }

    App.DisplayWindow(WindowID.c_str());
}

void Document::Close(OctaneGUI::Application& App, const std::shared_ptr<Node>& Item)
{
    if (Item == nullptr)
    {
        return;
    }

    App.CloseWindow(GetWindowID(Item).c_str());
}

Document::Document(OctaneGUI::Window* Window)
    : Container(Window)
{
    SetExpand(OctaneGUI::Expand::Both);

    const std::shared_ptr<OctaneGUI::MarginContainer> Margins = AddControl<OctaneGUI::MarginContainer>();
    Margins
        ->SetMargins({ 4.0f, 4.0f, 4.0f, 4.0f })
        .SetExpand(OctaneGUI::Expand::Both);
    
    m_Editor = Margins->AddControl<OctaneGUI::TextEditor>();
    m_Editor->SetExpand(OctaneGUI::Expand::Both);
}

Document& Document::SetNode(const std::shared_ptr<Node>& Item)
{
    m_Node = Item;
    return *this;
}

const std::weak_ptr<Node>& Document::GetNode() const
{
    return m_Node;
}

}
}
