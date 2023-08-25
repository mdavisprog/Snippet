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

#include "Node.h"
#include "OctaneGUI/OctaneGUI.h"

namespace Snippet
{
namespace Controls
{

//
// Node
//

Node::Node(OctaneGUI::Window* Window)
    : Container(Window)
{
    AddControl<OctaneGUI::Panel>()->SetExpand(OctaneGUI::Expand::Both);
    
    const std::shared_ptr<OctaneGUI::MarginContainer> Margins = AddControl<OctaneGUI::MarginContainer>();
    Margins
        ->SetMargins({ 4.0f, 4.0f, 4.0f, 4.0f })
        .SetExpand(OctaneGUI::Expand::Both);

    const std::shared_ptr<OctaneGUI::VerticalContainer> Contents = Margins->AddControl<OctaneGUI::VerticalContainer>();
    Contents->SetExpand(OctaneGUI::Expand::Width);

    m_Header = Contents->AddControl<Node::Header>();
}

Node& Node::SetName(const char32_t* Name)
{
    m_Header->Set(Name);
    Resize();
    return *this;
}

Node& Node::EditName()
{
    m_Header->Edit();
    Resize();
    return *this;
}

const char32_t* Node::Name() const
{
    return m_Header->Value();
}

void Node::Resize()
{
    const OctaneGUI::Vector2 Size { ChildrenSize() };
    SetSize({ std::max(Size.X, 200.0f), Size.Y });
}

//
// Node::Header
//

Node::Header::Header(OctaneGUI::Window* Window)
    : HorizontalContainer(Window)
{
    SetGrow(OctaneGUI::Grow::Center);
    SetExpand(OctaneGUI::Expand::Width);

    m_Label = AddControl<OctaneGUI::Text>();
    Set(U"New Snippet");

    m_Input = std::make_shared<OctaneGUI::TextInput>(Window);
    m_Input
        ->SetOnConfirm([this](OctaneGUI::TextInput&) -> void
            {
                FinishEdit();
            })
        .SetOnUnfocused([this](OctaneGUI::Control&) -> void
            {
                FinishEdit();
            });
}

Node::Header& Node::Header::Set(const char32_t* Value)
{
    m_Label->SetText(Value);
    return *this;
}

Node::Header& Node::Header::Edit()
{
    RemoveControl(m_Label);
    InsertControl(m_Input);
    m_Input
        ->SetText(m_Label->GetText())
        .SelectAll();
    GetWindow()->SetFocus(m_Input->Interaction());
    return *this;
}

const char32_t* Node::Header::Value() const
{
    return m_Label->GetText();
}

Node::Header& Node::Header::FinishEdit()
{
    RemoveControl(m_Input);
    InsertControl(m_Label);
    m_Label->SetText(m_Input->GetText());
    return *this;
}

}
}
