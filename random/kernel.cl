//OpenCL kernel to generate random HSV noise, makes pretty pictures when done wrong

//modified from http://code.google.com/p/libcl/source/browse/trunk/libCL/image/oclColor.cl?spec=svn48&r=48
//original code is:
//Copyright [2011] [Geist Software Labs Inc.]
float minComp(float4 v) {
    float t = (v.x<v.y) ? v.x : v.y;
    t = (t<v.z) ? t : v.z;
    return t;
}

float maxComp(float4 v) {
    float t = (v.x>v.y) ? v.x : v.y;
    t = (t>v.z) ? t : v.z;
    return t;
}

float4 RGBtoHSV(float4 RGB) {
    float4 HSV = (float4)0;
    float minVal = minComp(RGB);
    float maxVal = maxComp(RGB);
    float delta = maxVal - minVal;
    if (delta != 0) {
        float4 delRGB = ((((float4)(maxVal) - RGB)/6.0) + (delta/2.0))/delta;

        HSV.y = delta / maxVal;

        if ( RGB.x == maxVal )
            HSV.x = delRGB.z - delRGB.y;
        else if (RGB.y == maxVal)
            HSV.x = (1.0/3.0) + delRGB.x - delRGB.z;
        else if (RGB.z == maxVal)
            HSV.x = (2.0/3.0) + delRGB.y - delRGB.x;

        if (HSV.x < 0.0)
            HSV.x += 1.0;
        if (HSV.x > 1.0)
            HSV.x -= 1.0;
    }
    HSV.z = maxVal;
    HSV.w = RGB.w;
    return (HSV);
}

float4 HSVtoRGB(float4 HSV) {
    float4 RGB = (float4)0;
    if (HSV.z != 0) {
        float var_h = HSV.x * 6;
        float var_i = floor(var_h-0.000001);
        float var_1 = HSV.z * (1.0 - HSV.y);
        float var_2 = HSV.z * (1.0 - HSV.y * (var_h-var_i));
        float var_3 = HSV.z * (1.0 - HSV.y * (1-(var_h-var_i)));
        switch((int)(var_i)) {
        case 0: RGB = (float4)(HSV.z, var_3, var_1, HSV.w); break;
        case 1: RGB = (float4)(var_2, HSV.z, var_1, HSV.w); break;
        case 2: RGB = (float4)(var_1, HSV.z, var_3, HSV.w); break;
        case 3: RGB = (float4)(var_1, var_2, HSV.z, HSV.w); break;
        case 4: RGB = (float4)(HSV.z, var_1, var_2, HSV.w); break;
        default: RGB = (float4)(HSV.z, var_1, var_2, HSV.w); break;
        }
    }
    RGB.w = HSV.w;
    return (RGB);
}

//taken from http://cas.ee.ic.ac.uk/people/dt10/research/rngs-gpu-mwc64x.html, copyright unknown
uint rand(uint2 *state) {
    enum { A=4294883355U};
    uint x=(*state).x, c=(*state).y;  // Unpack the state
    uint res=x^c;                     // Calculate the result
    uint hi=mul_hi(x,A);              // Step the RNG
    x=x*A+c;
    c=hi+(x<c);
    *state=(uint2)(x,c);              // Pack the state back up
    return res;                       // Return the next result
}

//rest of file written by Nate Cybulski
uint2 rand_state_from_position_and_seed(int x, int y, long seed) {
    //changing how the initial state is generated can make interesting patterns instead of random noise
    uint2 state = (uint2)((seed >> 32) * x * (y + 1024), seed * (x + 1024) * y);
    for(int i = 0; i < 4; i++) {
        uint tmp = rand(&state);
        state.s0 *= tmp;
        tmp = rand(&state);
        state.s1 *= tmp;
    }
    return state;
}

float rand_prob(uint2 *state) {
    return ((rand(state) % 255) / 255.0);
}

__kernel void hsv_noise(float h_noise, float s_noise, float v_noise, long random_seed, read_only image2d_t in, write_only image2d_t out) {
    int x = get_global_id(0);
    int y = get_global_id(1);
    const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_FILTER_NEAREST | CLK_ADDRESS_CLAMP;
    float4 source_pixel = read_imagef(in, sampler, (int2)(x, y));
    float4 hsv = RGBtoHSV(source_pixel);
    uint2 state = rand_state_from_position_and_seed(x, y, random_seed);
    hsv.s0 = h_noise * rand_prob(&state) + (1 - h_noise) * hsv.s0;
    hsv.s1 = s_noise * rand_prob(&state) + (1 - s_noise) * hsv.s1;
    hsv.s2 = v_noise * rand_prob(&state) + (1 - v_noise) * hsv.s2;
    write_imagef(out, (int2)(x, y), HSVtoRGB(hsv));
}
