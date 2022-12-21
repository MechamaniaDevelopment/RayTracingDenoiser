/*
Copyright (c) 2022, NVIDIA CORPORATION. All rights reserved.

NVIDIA CORPORATION and its licensors retain all intellectual property
and proprietary rights in and to this software, related documentation
and any modifications thereto. Any use, reproduction, disclosure or
distribution of this software and related documentation without an express
license agreement from NVIDIA CORPORATION is strictly prohibited.
*/

#include "../Include/NRD.hlsli"
#include "STL.hlsli"

#define REBLUR_PERFORMANCE_MODE
#define REBLUR_DIFFUSE
#define REBLUR_SPECULAR
#define REBLUR_HITDIST_RECONSTRUCTION_5X5

#include "../Include/REBLUR/REBLUR_Config.hlsli"
#include "../Resources/REBLUR_DiffuseSpecular_HitDistReconstruction.resources.hlsli"

#include "../Include/Common.hlsli"
#include "../Include/REBLUR/REBLUR_Common.hlsli"
#include "../Include/REBLUR/REBLUR_DiffuseSpecular_HitDistReconstruction.hlsli"
