//========
// LPCD
//========

// takes one value between 0 and 1 and applies the non-linear warp to it
float lcpdWarpRemove(float n01)
{
	n01 = min(n01, 1.0f);

	if (n01 <= gRemoveLCPD_A1)
	{
		n01 = gRemoveLCPD_R * n01;
	}
	else
	{
		float t = (-gRemoveLCPD_b + sqrt(gRemoveLCPD_bb - gRemoveLCPD_am4 * (gRemoveLCPD_A1 - n01))) * gRemoveLCPD_am2inv;
		float2 y = gRemoveLCPD_B12 + t * gRemoveLCPD_VW;

		n01 = lerp(y.x, y.y, t);
	}

	return n01;
}

// takes [-1, 1] clipPos
float2 lcpdWarpRemove(float2 clipPos)
{
	// calc x
	clipPos.x = lcpdWarpRemove(abs(clipPos.x)) * sign(clipPos.x);
	clipPos.y = lcpdWarpRemove(abs(clipPos.y)) * sign(clipPos.y);
	return clipPos;
}

// takes one value between 0 and 1 and applies the non-linear warp to it
float lcpdWarpApply(float n01)
{
    n01 = min(n01, 1.0f);

    if (n01 <= gApplyLCPD_A1) 
    {
        n01 = gApplyLCPD_R * n01;
    }
    else 
    {
        float t = (-gApplyLCPD_b + sqrt(gApplyLCPD_bb - gApplyLCPD_am4 * (gApplyLCPD_A1 - n01))) * gApplyLCPD_am2inv;
        float2 y = gApplyLCPD_B12 + t * gApplyLCPD_VW;

        n01 = lerp(y.x, y.y, t);
    }

    return n01;
}

// takes [-1, 1] clipPos
float2 lcpdWarpApply(float2 clipPos)
{
    // calc x
    clipPos.x = lcpdWarpApply(abs(clipPos.x)) * sign(clipPos.x);
    clipPos.y = lcpdWarpApply(abs(clipPos.y)) * sign(clipPos.y);
    return clipPos;
}

float2 GetScreenUv_LCPD( float4x4 worldToClip, float3 X, bool killBackprojection = true )
{
    float4 clip = mul( worldToClip, float4( X, 1.0 ) );

    // use lcpd remove constants
    {
        clip.xy /= clip.w;
        clip.xy = lcpdWarpRemove(clip.xy);
    }

    float2 uv = clip.xy * float2(0.5, -0.5) + 0.5;

    if( killBackprojection )
        uv = clip.w < 0.0 ? 99999.0 : uv;

    return uv;
}

float3 getCurrentWorldPos_LCPD(float2 uv, float depth)
{
    float2 clipSpaceXY = uv * 2.0 - 1.0;
    clipSpaceXY = lcpdWarpApply(clipSpaceXY);
    return depth * (gFrustumForward.xyz + gFrustumRight.xyz * clipSpaceXY.x - gFrustumUp.xyz * clipSpaceXY.y);
}

float3 getCurrentWorldPos_LCPD(int2 pixelPos, float depth, float2 invRect, float4 frustomF, float4 frustumU, float4 frustumR)
{
    float2 clipSpaceXY = ((float2)pixelPos + float2(0.5, 0.5)) * invRect * 2.0 - 1.0;
    clipSpaceXY = lcpdWarpApply(clipSpaceXY);
    return depth * (frustomF.xyz + frustumR.xyz * clipSpaceXY.x - frustumU.xyz * clipSpaceXY.y);
}

float2 GetPrevUvFromMotion_LCPD( float2 uv, float3 X, float4x4 worldToClipPrev, float3 motionVector, compiletime const uint motionType = STL_WORLD_MOTION )
{
    float3 Xprev = X + motionVector;
    float2 uvPrev = GetScreenUv_LCPD( worldToClipPrev, Xprev );

    [flatten]
    if( motionType == STL_SCREEN_MOTION )
        uvPrev = uv + motionVector.xy;

    return uvPrev;
}