//========
// Pixel Density Warp (or PDW for short) applies/removes a non-linear warp that gets reconstructed/upscaled later
// in order to render more pixels at a certain focus point (e.g. the foveal or simply the center of the screen).
//========

// takes one value between 0 and 1 and removes the non-linear warp from it
float pdwRemove(float n01)
{
    n01 = min(n01, 1.0f);

    if (n01 <= gRemovePDW_A1)
    {
        n01 = gRemovePDW_R * n01;
    }
    else
    {
        float t = (-gRemovePDW_b + sqrt(gRemovePDW_bb - gRemovePDW_am4 * (gRemovePDW_A1 - n01))) * gRemovePDW_am2inv;
        float2 y = gRemovePDW_B12 + t * gRemovePDW_VW;

        n01 = lerp(y.x, y.y, t);
    }

    return n01;
}

// takes [-1, 1] clipPos
float2 pdwRemove(float2 clipPos)
{
    // calc x
    clipPos.x = pdwRemove(abs(clipPos.x)) * sign(clipPos.x);
    clipPos.y = pdwRemove(abs(clipPos.y)) * sign(clipPos.y);
    return clipPos;
}

// takes one value between 0 and 1 and applies the non-linear warp to it
float pdwApply(float n01)
{
    n01 = min(n01, 1.0f);

    if (n01 <= gApplyPDW_A1)
    {
        n01 = gApplyPDW_R * n01;
    }
    else
    {
        float t = (-gApplyPDW_b + sqrt(gApplyPDW_bb - gApplyPDW_am4 * (gApplyPDW_A1 - n01))) * gApplyPDW_am2inv;
        float2 y = gApplyPDW_B12 + t * gApplyPDW_VW;

        n01 = lerp(y.x, y.y, t);
    }

    return n01;
}

// takes [-1, 1] clipPos and applies the non-linear warp to it 
float2 pdwApply(float2 clipPos)
{
    // calc x
    clipPos.x = pdwApply(abs(clipPos.x)) * sign(clipPos.x);
    clipPos.y = pdwApply(abs(clipPos.y)) * sign(clipPos.y);
    return clipPos;
}

// This method is normally implemented in NRD's STL
// Since that's used in many other methods we've decided to change it here instead
float2 GetScreenUv_PDW(float4x4 worldToClip, float3 X, bool killBackprojection = true)
{
    float4 clip = mul(worldToClip, float4(X, 1.0));
    clip.xy /= clip.w;

    if (gEnablePDW != 0)
        clip.xy = pdwRemove(clip.xy);

    float2 uv = clip.xy * float2(0.5, -0.5) + 0.5;

    if (killBackprojection)
        uv = clip.w < 0.0 ? 99999.0 : uv;

    return uv;
}

float2 GetPrevUvFromMotion_PDW(float2 uv, float3 X, float4x4 worldToClipPrev, float3 motionVector, compiletime const uint motionType = STL_WORLD_MOTION)
{
    float3 Xprev = X + motionVector;
    float2 uvPrev = GetScreenUv_PDW(worldToClipPrev, Xprev);

    [flatten]
    if (motionType == STL_SCREEN_MOTION)
        uvPrev = uv + motionVector.xy;

    return uvPrev;
}

float ComputeParallax_PDW(float3 X, float2 uvForZeroParallax, float4x4 mWorldToClip, float2 rectSize, float unproject, float orthoMode)
{
    float3 clip = STL::Geometry::ProjectiveTransform(mWorldToClip, X).xyw;
    clip.xy /= clip.z;

    if (gEnablePDW != 0)
        clip.xy = pdwRemove(clip.xy);

    clip.y = -clip.y;

    float2 uv = clip.xy * 0.5 + 0.5;
    float invDist = orthoMode == 0.0 ? rsqrt(STL::Math::LengthSquared(X)) : rcp(clip.z);

    float2 parallaxInUv = uv - uvForZeroParallax;
    float parallaxInPixels = length(parallaxInUv * rectSize);
    float parallaxInUnits = PixelRadiusToWorld(unproject, orthoMode, parallaxInPixels, clip.z);
    float parallax = parallaxInUnits * invDist;

    return parallax * NRD_PARALLAX_NORMALIZATION;
}