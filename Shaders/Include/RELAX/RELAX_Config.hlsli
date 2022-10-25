/*
Copyright (c) 2022, NVIDIA CORPORATION. All rights reserved.

NVIDIA CORPORATION and its licensors retain all intellectual property
and proprietary rights in and to this software, related documentation
and any modifications thereto. Any use, reproduction, disclosure or
distribution of this software and related documentation without an express
license agreement from NVIDIA CORPORATION is strictly prohibited.
*/

#define RELAX_BLACK_OUT_INF_PIXELS                          1 // can be used to avoid killing INF pixels during composition
#define RELAX_SPEC_ACCUM_BASE_POWER                         0.5 // previously was 0.66 (less agressive accumulation, but virtual reprojection works well on flat surfaces and fixes the issue)
#define RELAX_MAX_ACCUM_FRAME_NUM                           255
#define RELAX_SPEC_ACCUM_CURVE                              1.0 // aggressiveness of history rejection depending on viewing angle (1 - low, 0.66 - medium, 0.5 - high)
#define RELAX_HIT_DIST_MIN_ACCUM_SPEED( r )                 lerp( 0.1, 0.2, STL::Math::Sqrt01( r ) )
#define RELAX_SPEC_DOMINANT_DIRECTION                       STL_SPECULAR_DOMINANT_DIRECTION_G2
#define RELAX_NORMAL_ULP                                    STL::Math::DegToRad( 0.05 )
#define RELAX_NORMAL_ENCODING_ERROR                         STL::Math::DegToRad( 0.5 )

// Shared constants common to all ReLAX denoisers
#define RELAX_SHARED_CB_DATA \
    NRD_CONSTANT( float4x4, gPrevWorldToClip ) \
    NRD_CONSTANT( float4x4, gPrevWorldToView ) \
    NRD_CONSTANT( float4x4, gWorldToClip ) \
    NRD_CONSTANT( float4x4, gWorldPrevToWorld ) \
    NRD_CONSTANT( float4x4, gViewToWorld ) \
    NRD_CONSTANT( float4, gFrustumRight ) \
    NRD_CONSTANT( float4, gFrustumUp ) \
    NRD_CONSTANT( float4, gFrustumForward ) \
    NRD_CONSTANT( float4, gPrevFrustumRight ) \
    NRD_CONSTANT( float4, gPrevFrustumUp ) \
    NRD_CONSTANT( float4, gPrevFrustumForward ) \
    NRD_CONSTANT( float4, gPrevCameraPosition ) \
    NRD_CONSTANT( float2, gResolutionScale) \
    NRD_CONSTANT( uint2, gRectOrigin ) \
    NRD_CONSTANT( float2, gRectOffset ) \
    NRD_CONSTANT( uint2, gRectSize ) \
    NRD_CONSTANT( float2, gInvResourceSize ) \
    NRD_CONSTANT( float2, gInvRectSize ) \
    NRD_CONSTANT( float2, gRectSizePrev ) \
    NRD_CONSTANT( float2, gMotionVectorScale ) \
    NRD_CONSTANT( uint, gIsWorldSpaceMotionEnabled ) \
    NRD_CONSTANT( float, gDebug ) \
    NRD_CONSTANT( float, gOrthoMode ) \
    NRD_CONSTANT( float, gUnproject ) \
    NRD_CONSTANT( uint, gFrameIndex ) \
    NRD_CONSTANT( float, gDenoisingRange ) \
    NRD_CONSTANT( float, gFramerateScale ) \
    NRD_CONSTANT( float, gCheckerboardResolveAccumSpeed ) \
    NRD_CONSTANT( float, gJitterDelta ) \
    NRD_CONSTANT( uint, gDiffMaterialMask ) \
    NRD_CONSTANT( uint, gSpecMaterialMask ) \
    NRD_CONSTANT( uint, gUseWorldPrevToWorld ) \
    \
    NRD_CONSTANT(uint, gEnablePDW) \
    NRD_CONSTANT(float, gApplyPDW_b) \
    NRD_CONSTANT(float, gApplyPDW_bb) \
    NRD_CONSTANT(float, gApplyPDW_am2inv) \
    NRD_CONSTANT(float, gApplyPDW_am4) \
    NRD_CONSTANT(float, gApplyPDW_A1) \
    NRD_CONSTANT(float2, gApplyPDW_B12) \
    NRD_CONSTANT(float2, gApplyPDW_VW) \
    NRD_CONSTANT(float, gApplyPDW_R) \
    NRD_CONSTANT(float, gRemovePDW_b) \
    NRD_CONSTANT(float, gRemovePDW_bb) \
    NRD_CONSTANT(float, gRemovePDW_am2inv) \
    NRD_CONSTANT(float, gRemovePDW_am4) \
    NRD_CONSTANT(float, gRemovePDW_A1) \
    NRD_CONSTANT(float2, gRemovePDW_B12) \
    NRD_CONSTANT(float2, gRemovePDW_VW) \
    NRD_CONSTANT(float, gRemovePDW_R) \
    \
    NRD_CONSTANT(float, gPad0) \
    NRD_CONSTANT(float, gPad1) \
    NRD_CONSTANT(float, gPad2) \
    \
    NRD_CONSTANT(uint, gPrevEnablePDW) \
    NRD_CONSTANT(float, gPrevApplyPDW_b) \
    NRD_CONSTANT(float, gPrevApplyPDW_bb) \
    NRD_CONSTANT(float, gPrevApplyPDW_am2inv) \
    NRD_CONSTANT(float, gPrevApplyPDW_am4) \
    NRD_CONSTANT(float, gPrevApplyPDW_A1) \
    NRD_CONSTANT(float2, gPrevApplyPDW_B12) \
    NRD_CONSTANT(float2, gPrevApplyPDW_VW) \
    NRD_CONSTANT(float, gPrevApplyPDW_R) \
    NRD_CONSTANT(float, gPrevRemovePDW_b) \
    NRD_CONSTANT(float, gPrevRemovePDW_bb) \
    NRD_CONSTANT(float, gPrevRemovePDW_am2inv) \
    NRD_CONSTANT(float, gPrevRemovePDW_am4) \
    NRD_CONSTANT(float, gPrevRemovePDW_A1) \
    NRD_CONSTANT(float2, gPrevRemovePDW_B12) \
    NRD_CONSTANT(float2, gPrevRemovePDW_VW) \
    NRD_CONSTANT(float, gPrevRemovePDW_R) \
    \
    NRD_CONSTANT(float, gPad3) \
    NRD_CONSTANT(float, gPad4) \
    NRD_CONSTANT(float, gPad5) \

#if( !defined RELAX_DIFFUSE && !defined RELAX_SPECULAR )
    #define RELAX_DIFFUSE
    #define RELAX_SPECULAR
#endif