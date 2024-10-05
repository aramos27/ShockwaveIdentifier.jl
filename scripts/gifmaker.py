import os
import sys
from PIL import Image

# Define the folder containing the PNG files and the output GIF path
if __name__ == '__main__':
    input_folder = '/'
    print(len(sys.argv))
    if len(sys.argv) >= 1:
        for input_folder in sys.argv[1:]:
            output_gif = f'{input_folder}.gif'

            # Get all PNG files in the folder
            png_files = sorted([f for f in os.listdir(input_folder) if f.endswith('.png')])

            # Ensure that the folder contains PNG files
            if not png_files:
                raise ValueError("No PNG files found in the specified folder.")

            # Load images
            images = [Image.open(os.path.join(input_folder, f)) for f in png_files]
            print("PNGs loaded")
            # Save images as a GIF
            images[0].save(
                output_gif,
                save_all=True,
                append_images=images[1:],
                duration=100,  # Duration in milliseconds per frame
                loop=0  # 0 means infinite loop
            )

            print(f"GIF saved as {output_gif}")
