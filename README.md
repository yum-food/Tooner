## Tooner

A toon shader for VRChat.

Features:
* PBR
* Decals
* Reflection probe override
* Min/max brightness
* Emissions
* Flat/realistic normals
* Matcaps
* Rim lighting
* Outlines
* Glitter
* Explosion
* Geometry scroll (similar to Poiyomi's shatterwave)
* UV scroll
* OKLCH color adjustment
* Clones
* Opaque, cutout, fade rendering modes
* Back/front/no culling modes
* LTCGI
* Shadow caster pass
* Extensive use of variants to minimize performance cost

Disclaimers:
1. This is a WIP.
2. I am not a graphics expert.
3. Stability is a non-goal. Keywords are likely to change in the interest of
   performance and simplicity.

Strawman FAQ

1. Why create another toon shader?

To deepen my understanding of lighting and to have a "simple" foundation on
top of which to create bespoke shader effects. lilToon and Poiyomi are both way
too fucking huge and complicated to fit my needs.

2. Does it work?

Sort of. I haven't implemented shadow receiving yet, so some water effects are
fucked up.

3. Is it optimized?

Sort of. I haven't benchmarked it. I know it's slower than Poiyomi.

I use keywords on every feature so it shouldn't be obscenely bad. But I haven't
gotten to the point of like, deduplicating all computation and shoving as much
as possible into the vertex shader. So it's like. Sort of optimized.

I'd like to strike a balance between performance and readability. Since it's
mostly for *my* use, I don't feel a need to make it totally optimal.

4. Demos?

This avatar uses it: [gumroad](https://yumfood.gumroad.com/l/lychee).

I'm working on a world but haven't published yet.

Will update this section with real demos later.

