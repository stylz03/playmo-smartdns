#!/usr/bin/env python3
"""
Generate QR code for WireGuard config locally (no EC2 needed)
Usage: python generate-qr-local.py <config-file>
"""

import sys
import os

try:
    import qrcode
    from PIL import Image
except ImportError:
    print("Error: Required packages not installed")
    print("Install with: pip install qrcode[pil]")
    sys.exit(1)

def generate_qr_code(config_file, output_name=None):
    """Generate QR code from WireGuard config file"""
    
    if not os.path.exists(config_file):
        print(f"Error: Config file not found: {config_file}")
        sys.exit(1)
    
    # Read config file
    with open(config_file, 'r', encoding='utf-8') as f:
        config_content = f.read()
    
    # Determine output name
    if output_name is None:
        base_name = os.path.splitext(os.path.basename(config_file))[0]
        output_name = base_name
    
    # Generate QR code
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(config_content)
    qr.make(fit=True)
    
    # Create image
    img = qr.make_image(fill_color="black", back_color="white")
    
    # Save PNG
    png_file = f"{output_name}.png"
    img.save(png_file)
    print(f"✅ PNG QR code saved: {png_file}")
    
    # Save SVG (if possible)
    try:
        import qrcode.image.svg
        factory = qrcode.image.svg.SvgPathImage
        svg_qr = qrcode.QRCode(image_factory=factory)
        svg_qr.add_data(config_content)
        svg_qr.make(fit=True)
        svg_img = svg_qr.make_image()
        svg_file = f"{output_name}.svg"
        svg_img.save(svg_file)
        print(f"✅ SVG QR code saved: {svg_file}")
    except:
        pass
    
    # Display QR code in terminal (if possible)
    try:
        qr_terminal = qrcode.QRCode()
        qr_terminal.add_data(config_content)
        qr_terminal.make(fit=True)
        print("\nQR Code (scan with WireGuard app):")
        print("=" * 50)
        qr_terminal.print_ascii(invert=True)
    except:
        pass
    
    print(f"\n✅ QR codes generated for: {config_file}")
    print(f"📁 Files saved in current directory")
    print(f"\nShare {png_file} with your customer!")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python generate-qr-local.py <config-file> [output-name]")
        print("Example: python generate-qr-local.py client1.conf")
        sys.exit(1)
    
    config_file = sys.argv[1]
    output_name = sys.argv[2] if len(sys.argv) > 2 else None
    
    generate_qr_code(config_file, output_name)

