

/*
Shifts through color hues.
Maintains same saturation and luminosity of the object that has from start.
Starts from hue 0, and cycles it through the end, loops over that.
@author kiantis.oe
*/







//HSL to RGB conversion function. By Cobalt Arkright. Released to the public under GNU GPL version 3.0 license.
//Takes a vector encoded HSL triplet and outputs a vector encoded RGB triplet.
 
//Input values should be in the following ranges: <float H(0 to 1), float S(0 to 1), float L(0 to 1)>. In this case, set h360 to "false."
//If you wish to use H(0 to 360), leave the boolean value "h360" set to true.
 
//Edit 12/27/2009: Cleaned up readability, played around a little bit with value calculation, and hopefully everything is more accurate now. failthfulll Moonwall brought it to my attention that the script wasn't working properly when using H ranges of 0 to 360. Based on my testing, it works now. If anyone else has a problem, feel free to PM me.
 
// HSL to RGB conversion function. By Clematide Oyen (Laura Aastha Bondi).
// Inspired by a function written by Alec Thilenius in this article: http://stackoverflow.com/questions/2353211/hsl-to-rgb-color-conversion
// Released to the public under GNU GPL version 3.0 license.
// Takes a vector encoded HSL triplet and outputs a vector encoded RGB triplet.
// Input HSL values should be in the standard format used in the LSL with the following ranges: <float H (0 to 1), float S (0 to 1), float L (0 to 1)>.
// Output is RGB values in the standard format used in the LSL with the following ranges: <float R (0 to 1), float G (0 to 1), float B (0 to 1)>.
 
vector HslToRgb(vector hsl)
{
    float r;
    float g;
    float b;
 
    if (hsl.y == 0.0) // If saturation is 0 the image is monochrome
        r = g = b = hsl.z;
    else
    {
        float q;
        if (hsl.z < 0.5)
            q = hsl.z * (1.0 + hsl.y);
        else
            q = hsl.z + hsl.y - hsl.z * hsl.y;
 
        float p = 2.0 * hsl.z - q;
 
        r = HueToRgb(p, q, hsl.x + 1.0 / 3.0);
        g = HueToRgb(p, q, hsl.x);
        b = HueToRgb(p, q, hsl.x - 1.0 / 3.0);
    }
    return <(r), (g), (b)>;
}
 
float HueToRgb(float p, float q, float t)
{
    if (t < 0.0) t += 1.0;
    if (t > 1.0) t -= 1.0;
    if (t < 1.0 / 6.0) return p + (q - p) * 6.0 * t;
    if (t < 1.0 / 2.0) return q;
    if (t < 2.0 / 3.0) return p + (q - p) * (2.0 / 3.0 - t) * 6.0;
    return p;
}

// RGB to HSL conversion function. By Clematide Oyen (Laura Aastha Bondi).
// Inspired by a function written by Alec Thilenius in this article: http://stackoverflow.com/questions/2353211/hsl-to-rgb-color-conversion
// Released to the public under GNU GPL version 3.0 license.
// Takes a vector encoded RGB triplet and outputs a vector encoded HSL triplet.
// Input RGB values should be in the standard format used in the LSL with the following ranges: <float R (0 to 1), float G (0 to 1), float B (0 to 1)>.
// Output is HSL values in the standard format used in the LSL with the following ranges: <float H (0 to 1), float S (0 to 1), float L (0 to 1)>.
 
vector RgbToHsl(vector rgb)
{
    float r = rgb.x;
    float g = rgb.y;
    float b = rgb.z;
    float h;
    float s;
    float l;
    float max;
    float min;
 
    // Looking for the max value among r, g and b
    if (r > g && r > b) max= r;
    else if (g > b) max = g;
    else max = b;
 
    // Looking for the min value among r, g and b
    if (r < g && r < b) min = r;
    else if (g < b) min = g;
    else min = b;
 
    l = (max + min) / 2.0;
 
    if (max == min)
    {
        h = 0.0;
        s = 0.0;
    }
    else
    {
        float d = max - min;
 
        if (l > 0.5) s = d / (2.0 - max - min);
        else s = d / (max + min);
 
        if (max == r) {
            if (g < b) h = (g - b) / d + 6.0;
            else h = (g - b) / d;
        }
        else if (max == g)
            h = (b - r) / d + 2.0;
        else
            h = (r - g) / d + 4.0;
        h /= 6.0;
    }
 
    return <h, s, l>;
}












vector colorHSL;

default {

  state_entry() {
    colorHSL = RgbToHsl(llGetColor(ALL_SIDES));
    colorHSL.x = 0;
    llSetTimerEvent(0.2);
  }

  timer() {
    colorHSL.x += 0.01;
    if (colorHSL.x >= 360) {
      colorHSL.x = 0;
    }
    llSetColor(HslToRgb(colorHSL), ALL_SIDES);
  }

}


