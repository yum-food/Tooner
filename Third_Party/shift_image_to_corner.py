"""
Shift image to corner, wrapping it toroidally.
"""

from PIL import Image
import numpy as np
import argparse
import os

def shift_to_corner(img, shift_side=True, shift_up=True):
    """
    Shifts an image to edges with toroidal wrapping based on specified directions.
    
    Args:
        img (PIL.Image): Input Pillow image
        shift_side (bool): Whether to shift horizontally to the right edge
        shift_up (bool): Whether to shift vertically to the top edge
    
    Returns:
        PIL.Image: Shifted image
    """
    # Convert image to numpy array
    img_array = np.array(img)
    
    # Get dimensions
    height, width = img_array.shape[:2]
    half_height = height // 2
    half_width = width // 2
    
    # Create new array for the shifted image
    shifted = np.zeros_like(img_array)
    
    if shift_side and shift_up:
        # Original behavior - shift to upper right corner
        shifted[half_height:, half_width:] = img_array[:half_height, :half_width]    # Q1 -> BR
        shifted[half_height:, :half_width] = img_array[:half_height, half_width:]    # Q2 -> BL
        shifted[:half_height, half_width:] = img_array[half_height:, :half_width]    # Q3 -> TR
        shifted[:half_height, :half_width] = img_array[half_height:, half_width:]    # Q4 -> TL
    elif shift_side:
        # Only shift horizontally to right
        shifted[:, half_width:] = img_array[:, :half_width]    # Left half -> Right
        shifted[:, :half_width] = img_array[:, half_width:]    # Right half -> Left
    elif shift_up:
        # Only shift vertically to top
        shifted[half_height:, :] = img_array[:half_height, :]  # Top half -> Bottom
        shifted[:half_height, :] = img_array[half_height:, :]  # Bottom half -> Top
    else:
        # No shift, return original image
        shifted = img_array.copy()
    
    # Convert back to PIL Image and return
    return Image.fromarray(shifted)

def shift_to_corner_from_file(image_path, output_path, shift_side=True, shift_up=True):
    """
    Wrapper function that shifts an image file to edges with toroidal wrapping.
    
    Args:
        image_path (str): Path to the input image
        output_path (str): Path where the shifted image will be saved
        shift_side (bool): Whether to shift horizontally to the right edge
        shift_up (bool): Whether to shift vertically to the top edge
    
    Returns:
        PIL.Image: Shifted image
    """
    img = Image.open(image_path)
    result = shift_to_corner(img, shift_side=shift_side, shift_up=shift_up)
    result.save(output_path)
    return result

def get_output_path(input_path):
    """
    Generate output path by adding '_shifted' before the file extension.
    
    Args:
        input_path (str): Path to the input image
    Returns:
        str: Path for the output image
    """
    base, ext = os.path.splitext(input_path)
    return f"{base}_shifted{ext}"

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Shift an image to the corner with toroidal wrapping.')
    parser.add_argument('input_image', help='Path to the input image file')
    parser.add_argument('--no-side', action='store_false', dest='shift_side',
                      help='Disable horizontal shifting (default: enabled)')
    parser.add_argument('--no-up', action='store_false', dest='shift_up',
                      help='Disable vertical shifting (default: enabled)')
    
    args = parser.parse_args()
    output_path = get_output_path(args.input_image)
    
    shift_to_corner_from_file(args.input_image, output_path, 
                             shift_side=args.shift_side, 
                             shift_up=args.shift_up)
