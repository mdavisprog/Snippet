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

#include "Controls/ConnectionButton.h"
#include "Frontend.h"
#include "OctaneGUI/OctaneGUI.h"

#include <cstdio>

int main(int argc, char** argv)
{
    const char* Json = R"({
    "Theme": "Resources/Themes/Dark.json",
    "Windows": {
        "Main": {"Title": "Snippet", "Width": 1280, "Height": 720,
            "MenuBar": {"Items": [
                {"Text": "File", "ID": "File", "Items": [
                    {"Text": "Quit", "ID": "Quit"}
                ]}
            ]},
            "Body": {"Controls": [
                {"Type": "MarginContainer", "Expand": "Both", "Margins": [4, 4, 4, 4], "Controls": [
                    {"Type": "VerticalContainer", "Expand": "Both", "Controls": [
                        {"Type": "Canvas", "ID": "Canvas", "Expand": "Both", "BackgroundColor": [96, 96, 96, 255]},
                        {"Type": "HorizontalContainer", "Expand": "Width", "Controls": [
                            {"Type": "MarginContainer", "Expand": "Both", "Controls": [
                                {"Type": "Panel", "Expand": "Both"},
                                {"Type": "HorizontalContainer", "Expand": "Width", "ID": "StatusBar"}
                            ]}
                        ]}
                    ]}
                ]}
            ]}
        }
    }
})";

    OctaneGUI::Application Application;
    Frontend::Initialize(Application);

    std::unordered_map<std::string, OctaneGUI::ControlList> Controls;
    Application
        .SetCommandLine(argc, argv)
        .Initialize(Json, Controls);
    
    Controls["Main"].To<OctaneGUI::MenuItem>("File.Quit")->SetOnPressed([&](const OctaneGUI::TextSelectable&) -> void
        {
            Application.Quit();
        });

    const std::shared_ptr<OctaneGUI::Container> StatusBar = Controls["Main"].To<OctaneGUI::Container>("StatusBar");
    const std::shared_ptr<Snippet::Controls::ConnectionButton> ConnectionButton = StatusBar->AddControl<Snippet::Controls::ConnectionButton>();

    return Application.Run();
}
