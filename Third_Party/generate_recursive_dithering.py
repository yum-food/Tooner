import numpy as np
from PIL import Image, ImageDraw
import argparse
import math

def create_circle_image(res, radius, center=None):
    """Create a binary image with a white circle on black background."""
    if center is None:
        center = (res/2, res/2)

    img = Image.new('L', (res, res), 0)
    draw = ImageDraw.Draw(img)

    # Convert radius and center to pixels
    r_px = int(radius * res)
    cx, cy = int(center[0]), int(center[1])

    # Draw white circle (255)
    draw.ellipse([cx-r_px, cy-r_px, cx+r_px, cy+r_px], fill=255)

    # Handle edge case 1: circle is on left edge
    if cx == 0:
        cx2 = res
        draw.ellipse([cx2-r_px, cy-r_px, cx2+r_px, cy+r_px], fill=255)
    # Handle edge case 2: circle is on top edge
    if cy == 0:
        cy2 = res
        draw.ellipse([cx-r_px, cy2-r_px, cx+r_px, cy2+r_px], fill=255)
    # Handle edge case 3: circle is on top left corner
    if cx == 0 and cy == 0:
        cx2 = res
        cy2 = res
        draw.ellipse([cx2-r_px, cy2-r_px, cx2+r_px, cy2+r_px], fill=255)
    return img

def get_bayer_location(nth, res):
    """
    Returns the normalized location (x, y) for the nth dot in a recursive Bayer dithering pattern.
    
    The pattern is constructed by writing nth in base-4 and mapping each digit as follows:
        0 -> (0, 0)
        1 -> (1, 1)
        2 -> (1, 0)
        3 -> (0, 1)
        
    Each digit is weighted by successive powers of 1/2 so that:
        x = sum_{i=0}^{k-1} (digit_x(i)) / 2^(i+1)
        y = sum_{i=0}^{k-1} (digit_y(i)) / 2^(i+1)
        
    The parameter `res` is expected to be a power-of-two (and in practice an even number); we let k = (res+1)//2.
    For example:
      - For res == 2, k = 1, and the function returns one of: (0,0), (0.5,0.5), (0.5,0), or (0,0.5).
      - For res == 4, k = 2, and the function returns positions on a 4×4 grid.
      - For res == 8, k = 4, and the function returns positions on a 16×16 grid.
      
    If nth is greater than or equal to 4^k then an error is raised.
    """
    k = (res + 1) // 2  # determine the number of base-4 digits to use
    if nth >= 4 ** k:
        raise ValueError(f"nth value {nth} too large for given res {res} (max is {4**k - 1}).")
    
    x, y = 0.0, 0.0
    # Process each base-4 digit (least significant first)
    for i in range(k):
        digit = nth % 4
        nth //= 4
        weight = 1 / (2 ** (i + 1))
        if digit == 0:
            dx, dy = 0, 0
        elif digit == 1:
            dx, dy = 1, 1
        elif digit == 2:
            dx, dy = 1, 0
        elif digit == 3:
            dx, dy = 0, 1
        else:
            raise ValueError("Unexpected digit encountered while converting number to base-4")
        x += dx * weight
        y += dy * weight
    return (x, y)


def main():
    parser = argparse.ArgumentParser(description="Generate dot and circle images.")
    parser.add_argument("--res", type=int, default=128, help="Resolution of the images.")
    args = parser.parse_args()

    res = args.res
    initial_area = 0.1

    bayer_res = 16
    total_layers = bayer_res * bayer_res
    # Calculate number of digits needed for zero padding
    num_digits = len(str(total_layers))

    for layer in range(1, total_layers + 1):
        # Calculate radius for this layer (split area among n circles)
        radius = math.sqrt(initial_area/layer) * res
        
        # Create the combined image for this layer
        layer_img = Image.new('L', (res, res), 0)
        
        # Place n circles according to Bayer pattern
        for n in range(layer):
            # Get normalized coordinates from Bayer pattern
            x, y = get_bayer_location(n, bayer_res) 
            # Convert to pixel coordinates
            center = (x * res, y * res)
            # Create and add circle
            circle = create_circle_image(res, radius/res, center=center)

            layer_img = Image.fromarray(np.maximum(np.array(layer_img), np.array(circle)))
        
        # Save the layer with zero-padded number
        layer_img.save(f"dots_L{layer:0{num_digits}d}.png")

if __name__ == "__main__":
    main()
