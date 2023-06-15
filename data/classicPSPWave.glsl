// PSP Classic Wave by ParkingLotGames (github/ParkingLotGames)
// https://www.shadertoy.com/view/ddV3DK
// Original for Unity: https://github.com/ParkingLotGames/PSP-Classic-Wave-Unity-Shader
// License: MIT

/*
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
*/

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 _TopColor = vec4(0.04, 0.19, 0.54, 1.0);
    vec4 _BottomColor = vec4(0.04, 0.69, 0.87, 1.0);
    
    vec2 uv = fragCoord/iResolution.xy;
    
    float _Frequency = 4.29;
    float _OuterWavesAmplitude = 0.5;
    float _InnerWavesAmplitude = 0.18;
    float _OuterWavesSpeed = 0.044;
    float _InnerWavesSpeed = 0.064;
    float _OuterWave1Falloff = 2.0;
    float _OuterWave2Falloff = 2.0;
    float _InnerWave1Falloff = 1.0;
    float _InnerWave2Falloff = 1.0;

    vec3 white = vec3(1.0, 1.0, 1.0);
    
    float topOuterWave = sin((uv.x + (iTime * (_OuterWavesSpeed + (0.0025 * 1.0)))) * _Frequency) * _OuterWavesAmplitude;
    float bottomOuterWave = sin((uv.x + (iTime * (_OuterWavesSpeed + (0.0025 * 20.0)))) * _Frequency) * _OuterWavesAmplitude;
    float topInnerWave = sin((uv.x + (iTime * (_InnerWavesSpeed + (0.0025 * 8.0)))) * _Frequency) * _InnerWavesAmplitude;
    float bottomInnerWave = sin((uv.x + (iTime * (_InnerWavesSpeed + (0.0025 * 40.0)))) * _Frequency) * _InnerWavesAmplitude;

    float topOuterWaveFalloff = topOuterWave;
    float bottomOuterWaveFalloff = bottomOuterWave;
    float topInnerWaveFalloff = topInnerWave;
    float bottomInnerWaveFalloff = bottomInnerWave;

    topOuterWave += 1.0 - (1.0 - uv.y) * 6.0;
    bottomOuterWave += 1.0 - (uv.y * 6.0);
    topInnerWave += 1.0 - (uv.y) * 2.5;
    bottomInnerWave += 1.0 - (1.0 - uv.y) * 2.5;

    topOuterWaveFalloff += 1.0 - (1.0 - uv.y - 0.2) * 6.0;
    bottomOuterWaveFalloff += 1.0 - ((uv.y - 0.2) * 6.0);
    topInnerWaveFalloff += 1.0 - ((uv.y - 0.1) * 2.2);
    bottomInnerWaveFalloff += 1.0 - (((1.0 - uv.y - 0.1)) * 2.2);

    float wave1 = 1.0 - smoothstep(0.0, 0.025, topOuterWave);
    float wave2 = 1.0 - smoothstep(0.0, 0.025, bottomOuterWave);
    float wave3 = 1.0 - smoothstep(0.0, 0.025, topInnerWave);
    float wave4 = 1.0 - smoothstep(0.0, 0.025, bottomInnerWave);

    float wave1Falloff = 1.0 - smoothstep(0.0, _OuterWave1Falloff, topOuterWaveFalloff);
    float wave2Falloff = 1.0 - smoothstep(0.0, _OuterWave2Falloff, bottomOuterWaveFalloff);
    float wave3Falloff = 1.0 - smoothstep(0.0, _InnerWave1Falloff, topInnerWaveFalloff);
    float wave4Falloff = 1.0 - smoothstep(0.0, _InnerWave2Falloff, bottomInnerWaveFalloff);

    wave1 -= wave1Falloff;
    wave2 -= wave2Falloff;
    wave3 -= wave3Falloff;
    wave4 -= wave4Falloff;

    wave1 = clamp(wave1, 0.0, 1.0);
    wave2 = clamp(wave2, 0.0, 1.0);
    wave3 = clamp(wave3, 0.0, 1.0);
    wave4 = clamp(wave4, 0.0, 1.0);

    float wave = wave1 + wave2 + wave3 + wave4;
    vec4 waveContribution = vec4(white,wave);
    vec4 background = vec4(mix(_BottomColor.rgb, _TopColor.rgb, uv.y), 1.0);

    fragColor = mix(background, waveContribution, wave);
}
