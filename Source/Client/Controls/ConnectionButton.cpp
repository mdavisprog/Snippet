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

#include "ConnectionButton.h"
#include "OctaneGUI/OctaneGUI.h"

namespace Snippet
{
namespace Controls
{

ConnectionButton::ConnectionButton(OctaneGUI::Window* Window)
    : ImageButton(Window)
{
    SetProperty(OctaneGUI::ThemeProperties::Button_Padding, OctaneGUI::Vector2{0.0f, 0.0f});
    UpdateColors();

    m_LinkOn = Window->App().GetTextureCache().LoadSVG("Resources/LinkOn.svg", 20, 20);
    m_LinkOff = Window->App().GetTextureCache().LoadSVG("Resources/LinkOff.svg", 20, 20);
    SetTexture(m_LinkOff);

    m_Timer = Window->CreateTimer(1000, false, [this]() -> void
        {
            OnTimer();
        });
    m_Timer->Start();
}

void ConnectionButton::OnTimer()
{
}

void ConnectionButton::UpdateColors()
{
    if (m_ConnectionStatus != Common::ConnectionStatus::Connected)
    {
        SetProperty(OctaneGUI::ThemeProperties::Button, OctaneGUI::Color{70, 0, 0, 255});
        SetProperty(OctaneGUI::ThemeProperties::Button_Hovered, OctaneGUI::Color{115, 0, 0, 255});
        SetProperty(OctaneGUI::ThemeProperties::Button_Pressed, OctaneGUI::Color{170, 0, 0, 255});
    }
    else
    {
        SetProperty(OctaneGUI::ThemeProperties::Button, OctaneGUI::Color{0, 70, 0, 255});
        SetProperty(OctaneGUI::ThemeProperties::Button_Hovered, OctaneGUI::Color{0, 115, 0, 255});
        SetProperty(OctaneGUI::ThemeProperties::Button_Pressed, OctaneGUI::Color{0, 170, 0, 255});
    }
}

}
}
