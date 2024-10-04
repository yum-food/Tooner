## Tooner

My toon shader for VRChat. I use this on my personal and commercial models.
It's semi optimized and a little scuffed.

![Bistro demo](Textures/bistro_demo.png)

Features (maybe out of date):
* PBR
* Emissions
* Outlines
  * With/without stenciling
* Glitter
* Explosion
* PBR detail maps x4
  * Albedo, emission, normal, metallic, roughness, mask
* Decals x4
  * Albedo, emission, angle
* Matcaps x2
  * Add, mul, replace, sub, min, max
  * Quantization
* Rim lighting x2
  * Add, mul, replace, sub, min, max
  * Glitter
  * Quantization
* Rendering modes: opaque, cutout, fade, transparent, transclipping
* Culling modes: front, back, none
* OKLCH color adjustment
* Reflection probe (cubemap) override
* Lighting min/max
* Flat/realistic normals
* Geometry scroll (similar to Poiyomi's shatterwave)
* UV scroll
* Clones
* LTCGI
* Shadows (both casting and receiving)
* Gimmicks
  * Vertex location quantization (object space)
  * Vertex location scaling (object space)

Disclaimers:
1. This is a WIP.
2. I am not a graphics expert.
3. Stability is a non-goal. Keywords are likely to change in the interest of
   performance and simplicity.
4. This is not a supported product. Support is only provided when used in
   conjunction with one of my commercially available products.

To use it, import the git repo into your project's Assets folder then select
the shader `yum_food/tooner_inlined`. To generate a new inlined shader from
sources, select `Tools/yum_food/Shader Inliner` and point it at your
Tooner.shader.

### Strawman FAQ

1. Why create another toon shader?

To deepen my understanding of lighting and to have a "simple" foundation on
top of which to create bespoke shader effects. lilToon and Poiyomi are both way
too fucking huge and complicated to fit my needs.

2. Does it work?

Yes.

3. Is it optimized?

Somewhat.

I use static keywords on every feature, so you don't pay for anything you don't
use. I use branchless programming wherever appropriate. I do make extensive use
of dynamic branching where I know it won't induce thread divergence.

The goal is to strike a balance between performance and readability. Golfing
away nanoseconds is not something I want to spend my limited time on Earth
doing.

4. Demos?

TODO. See the screenshot at the top of the page for now.

