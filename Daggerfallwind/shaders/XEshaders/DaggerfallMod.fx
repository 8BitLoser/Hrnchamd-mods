// DaggerfallMod beta
// by Hrnchamd

static const float saturation = 0.70;
static const float letterbox = 0.425;
static const int rez_x = 360, rez_y = 320;

float2 rcpres;

texture lastshader;
texture lastpass;

sampler s0 = sampler_state { texture = <lastshader>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };

float4 lowrez(in float2 tex : TEXCOORD) : COLOR0
{
    // Pixelize
    tex.x = floor(tex.x * rez_x) / rez_x;
    tex.y = floor(tex.y * rez_y) / rez_y;
    float4 c = tex2D(s0, tex);

    // De-saturation
    float lumi = 0.2126*c.r*c.r + 0.7152*c.g*c.g + 0.0722*c.b*c.b;
    float gray = sqrt(lumi);
    c.rgb = lerp(gray.xxx, c.rgb, saturation);

    // Letterboxing
    float2 d = tex - float2(0.5, 0.5);
    c.rgb *= smoothstep(letterbox + 0.005, letterbox, abs(d.y));

    return c;
}

technique T0 < string MGEinterface = "MGE XE 0"; string category = "final"; int priorityAdjust = 1000; >
{
    pass { PixelShader = compile ps_3_0 lowrez(); }
}
