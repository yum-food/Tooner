## Tooner

My toon shader for VRChat. I use this on my personal and commercial models.
It's semi optimized and a little scuffed.

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

To use it, import the git repo into your project's Assets folder then select
the shader `yum_food/Tooner`.

### Strawman FAQ

1. Why create another toon shader?

To deepen my understanding of lighting and to have a "simple" foundation on
top of which to create bespoke shader effects. lilToon and Poiyomi are both way
too fucking huge and complicated to fit my needs.

2. Does it work?

I think so?

3. Is it optimized?

Sort of.

I use static keywords on every feature, so you don't pay for anything you don't
use. I use branchless programming wherever appropriate. Dynamic branches are
only used where I either know they won't cause thread divergence, or where they
can't be avoided.

I'd like to strike a balance between performance and readability. Since it's
mostly for *my* use, I don't feel a need to make it totally optimal.

4. Demos?

This avatar uses it: [gumroad](https://yumfood.gumroad.com/l/lychee).

I'm working on a world but haven't published yet.

Will update this section with real demos later.

