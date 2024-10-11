import os
from PIL import Image

def pngs_to_gif(input_folder, output_gif=None, duration=100, loop=0):
    """
    Converts all PNG images in a folder to an animated GIF.

    Parameters:
    - input_folder (str): The path to the folder containing PNG files.
    - output_gif (str): The output path for the GIF. If None, defaults to <input_folder>.gif.
    - duration (int): Duration in milliseconds per frame. Default is 100ms.
    - loop (int): Number of loops. 0 means infinite loop. Default is 0.

    Returns:
    - str: The path of the saved GIF.
    """
    # Set output GIF path if not provided
    if output_gif is None:
        output_gif = f'{input_folder}.gif'

    # Get all PNG files in the folder
    png_files = sorted([f for f in os.listdir(input_folder) if f.endswith('.png')])

    # Ensure that the folder contains PNG files
    if not png_files:
        raise ValueError("No PNG files found in the specified folder.")

    # Load images
    images = [Image.open(os.path.join(input_folder, f)) for f in png_files]
    print(f"{len(images)} PNGs loaded")

    n = len(png_files)
    optimalDuration = 50 * (2 - (np.exp(0.02 * n * (150) - 1) / np.exp(0.02 * n * (150) + 1)))

    # Save images as a GIF
    images[0].save(
        output_gif,
        save_all=True,
        append_images=images[1:],
        duration=optimalDuration,  # Duration in milliseconds per frame
        loop=loop  # 0 means infinite loop
    )

    print(f"GIF saved as {output_gif}")
    return output_gif

pngs_to_gif("frames/10-11-19-42-52")