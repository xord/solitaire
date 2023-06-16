import SwiftUI


struct MenuScreen: View {

    @Binding var isVisible: Bool

    var body: some View {
        NavigationView {
            List {
                PrivacyPolicy()
                Licenses()
            }
            .navigationTitle("\(Strings.appName.s) v\(Helper.appVersion)")
            .navigationBarItems(leading: BackButton())
        }
    }

    private func BackButton() -> some View {
        Button {
            isVisible = false
        } label: {
            Text(Strings.close.s)
        }
    }

    private func PrivacyPolicy() -> some View {
        Button {
            Helper.openURL(URL(string: "https://xord.org/rubysolitaire/privacy_policy.html")!)
        } label: {
            Text(Strings.menuPrivacyPolicy.s)
        }
    }

    private func Licenses() -> some View {
        NavigationLink {
            LicensesScreen()
        } label: {
            Text(Strings.menuLicenses.s)
        }
    }
}


struct LicensesScreen: View {
    var body: some View {
        ScrollView {
            Text("""
# GLSL Shaders

## Cosmic 2

// Started as Star Nest by Pablo RomÃ¡n Andrioli
// Modifications by Beibei Wang and Huw Bowles.
// This content is under the MIT License.

https://www.shadertoy.com/view/XllGzN

## Classic PSP Wave

MIT License

Copyright (c) 2023 Parking Lot Studio

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

https://www.shadertoy.com/view/ddV3DK

## Reflective hexes

// CC0: Reflective hexes
https://creativecommons.org/publicdomain/zero/1.0/

https://www.shadertoy.com/view/ds2XRt

## Colorful underwater bubbles II

// CCO: Colorful underwater bubbles II
https://creativecommons.org/publicdomain/zero/1.0/

https://www.shadertoy.com/view/mlBSWc


# Assets

## Bg-patterns
https://bg-patterns.com/

## 効果音ラボ
https://soundeffect-lab.info/


# Licenses

## Ruby

Copyright (C) 1993-2013 Yukihiro Matsumoto. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.
""")
            .padding(10)
        }
        .navigationTitle(Strings.menuLicenses.s)
    }
}
