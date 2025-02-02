import numpy as np
from PIL import Image, ImageDraw
import argparse
import math

from shift_image_to_corner import shift_to_corner

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
    return img

def main():
    parser = argparse.ArgumentParser(description="Generate dot and circle images.")
    parser.add_argument("--res", type=int, default=128, help="Resolution of the images.")
    args = parser.parse_args()

    res = args.res
    goal_area = 0.1
    # a = pi * r^2
    # r = sqrt(a / pi)
    initial_r = math.sqrt(goal_area / math.pi) * res  # Start with a circle that fills 1/4 of the image
    
    # Calculate areas and radii for each layer
    initial_area = math.pi * (initial_r/res)**2
    
    # Layer 1: Single circle in corner
    r1 = math.sqrt(initial_area/1) * res  # Calculate radius consistently with other layers
    base_img = create_circle_image(res, r1/res)
    corner_img = shift_to_corner(base_img)
    corner_img.save("dots_L1.png")
    
    # Layer 2: Two circles, split area
    r2 = math.sqrt(initial_area/2) * res  # New radius for each circle
    # Create corner circle
    corner_img = shift_to_corner(create_circle_image(res, r2/res))
    # Create center circle
    center_img = create_circle_image(res, r2/res)
    # Combine images
    layer2 = Image.fromarray(np.maximum(np.array(corner_img), np.array(center_img)))
    layer2.save("dots_L2.png")
    
    # Layer 3: Three circles
    r3 = math.sqrt(initial_area/3) * res
    # Create corner and center circles as before
    corner_img = shift_to_corner(create_circle_image(res, r3/res))
    center_img = create_circle_image(res, r3/res)
    # Create top circle
    top_img = shift_to_corner(create_circle_image(res, r3/res), shift_side=False)
    # Combine images
    layer3 = Image.fromarray(np.maximum.reduce([
        np.array(corner_img),
        np.array(center_img),
        np.array(top_img)
    ]))
    layer3.save("dots_L3.png")
    
    # Layer 4: Four circles
    r4 = math.sqrt(initial_area/4) * res
    # Create corner and center circles
    corner_img = shift_to_corner(create_circle_image(res, r4/res))
    center_img = create_circle_image(res, r4/res)
    # Create top and right circles
    top_img = shift_to_corner(create_circle_image(res, r4/res), shift_side=False)
    right_img = shift_to_corner(create_circle_image(res, r4/res), shift_up=False)
    # Combine images

    layer4 = Image.fromarray(np.maximum.reduce([
        np.array(corner_img),
        np.array(center_img),
        np.array(top_img),
        np.array(right_img)
    ]))
    layer4.save("dots_L4.png")

if __name__ == "__main__":
    main()