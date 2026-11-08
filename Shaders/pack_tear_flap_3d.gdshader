shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, diffuse_burley, specular_schlick_ggx;

// The strip of a pack being torn off, both sides of it: see pack_front_surface.gdshaderinc.

#define PACK_TEAR_FLAP
#include "res://Shaders/pack_front_surface.gdshaderinc"
