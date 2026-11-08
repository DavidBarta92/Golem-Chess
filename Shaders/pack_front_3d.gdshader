shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back, diffuse_burley, specular_schlick_ggx;

// A pack's printed face: see pack_front_surface.gdshaderinc.

#include "res://Shaders/pack_front_surface.gdshaderinc"
