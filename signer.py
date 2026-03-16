#!/usr/bin/env python3
"""
Simple IPA Signer - Because 3uTools is trash
"""

import os
import sys
import shutil
import plistlib
import subprocess
import tempfile
import zipfile
import argparse
from pathlib import Path

class IPASigner:
    def __init__(self):
        self.temp_dir = tempfile.mkdtemp()
        
    def cleanup(self):
        shutil.rmtree(self.temp_dir, ignore_errors=True)
        
    def extract_ipa(self, ipa_path):
        """Extract IPA to temp directory"""
        print(f"📦 Extracting {ipa_path}...")
        with zipfile.ZipFile(ipa_path, 'r') as zip_ref:
            zip_ref.extractall(self.temp_dir)
        
        # Find .app
        payload_dir = Path(self.temp_dir) / "Payload"
        app_files = list(payload_dir.glob("*.app"))
        if not app_files:
            raise Exception("No .app found in Payload")
        return app_files[0]
    
    def verify_plist(self, app_path):
        """Check if Info.plist is valid XML"""
        plist_path = app_path / "Info.plist"
        
        # Read first few bytes
        with open(plist_path, 'rb') as f:
            header = f.read(6)
            
        if header.startswith(b'bplist'):
            print("❌ Binary plist detected - converting to XML")
            # Convert binary to XML
            with open(plist_path, 'rb') as f:
                plist_data = plistlib.load(f)
            with open(plist_path, 'wb') as f:
                plistlib.dump(plist_data, f, fmt=plistlib.FMT_XML)
            print("✅ Converted to XML")
        elif header.startswith(b'<?xml'):
            print("✅ XML plist detected")
        else:
            print(f"⚠️ Unknown plist format: {header}")
            
        # Validate with plutil if available
        try:
            subprocess.run(['plutil', '-lint', str(plist_path)], check=True)
            print("✅ Plist validation passed")
        except:
            print("⚠️ plutil not available or validation failed")
            
    def sign(self, app_path, certificate=None):
        """Sign the app using ldid or codesign"""
        print(f"🔏 Signing {app_path}...")
        
        # Try codesign first (macOS)
        codesign = shutil.which('codesign')
        if codesign:
            cmd = [codesign, '-f', '-s', certificate or '-', str(app_path)]
            try:
                subprocess.run(cmd, check=True, capture_output=True)
                print("✅ Signed with codesign")
                return
            except:
                pass
        
        # Fallback to ldid
        ldid = shutil.which('ldid')
        if ldid:
            cmd = [ldid, '-S', str(app_path)]
            try:
                subprocess.run(cmd, check=True, capture_output=True)
                print("✅ Signed with ldid")
                return
            except:
                pass
                
        print("❌ No signing tool found")
        raise Exception("Signing failed")
    
    def package_ipa(self, app_path, output_path):
        """Create new IPA"""
        print(f"📦 Creating {output_path}...")
        
        # Ensure Payload directory exists in output
        payload_in_zip = "Payload"
        
        with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
            app_name = app_path.name
            for root, _, files in os.walk(app_path):
                for file in files:
                    full_path = os.path.join(root, file)
                    arcname = os.path.join(payload_in_zip, app_name, 
                                          os.path.relpath(full_path, app_path))
                    zipf.write(full_path, arcname)
        
        print(f"✅ IPA created: {output_path}")
        
    def run(self, ipa_path, output_path=None, certificate=None):
        try:
            # Extract
            app_path = self.extract_ipa(ipa_path)
            
            # Verify/fix plist
            self.verify_plist(app_path)
            
            # Sign
            self.sign(app_path, certificate)
            
            # Package
            if not output_path:
                output_path = ipa_path.replace('.ipa', '-signed.ipa')
            self.package_ipa(app_path, output_path)
            
            print(f"\n🎉 Success! Signed IPA: {output_path}")
            
        finally:
            self.cleanup()

def main():
    parser = argparse.ArgumentParser(description='Simple IPA Signer')
    parser.add_argument('ipa', help='Path to IPA file')
    parser.add_argument('-o', '--output', help='Output IPA path')
    parser.add_argument('-c', '--cert', help='Certificate name (for codesign)')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.ipa):
        print(f"❌ File not found: {args.ipa}")
        sys.exit(1)
        
    signer = IPASigner()
    signer.run(args.ipa, args.output, args.cert)

if __name__ == '__main__':
    main()
