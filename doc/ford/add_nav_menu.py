#!/usr/bin/env python3
"""
Add custom navigation menu to FORD generated documentation.
This script injects a documentation menu into the generated HTML files.
"""

import os
import re
from pathlib import Path

def get_nav_menu_html(depth):
    """Get navigation menu HTML with correct relative paths based on file depth."""
    # Calculate relative path prefix based on depth
    if depth == 0:
        prefix = ""
    else:
        prefix = "../" * depth
    
    nav_menu = f'''
<!-- Documentation Navigation Menu -->
<div class="ford-doc-nav" style="background-color: #161B22; border-top: 1px solid #30363D; padding: 12px 20px; margin-top: 20px;">
  <div style="max-width: 1200px; margin: 0 auto;">
    <div style="display: flex; flex-wrap: wrap; gap: 20px; font-size: 14px;">
      <div>
        <strong style="color: #6BA3F5;">📚 Documentation Pages</strong>
        <ul style="list-style: none; padding: 8px 0 0 0; margin: 0;">
          <li><a href="{prefix}page/YAMBO_THEORY_DOCUMENTATION.html" style="color: #6BA3F5;">Theory Guide</a></li>
          <li><a href="{prefix}page/INPUT_FLAGS.html" style="color: #6BA3F5;">Input Flags</a></li>
          <li><a href="{prefix}page/IO_System_Architecture.html" style="color: #6BA3F5;">I/O System</a></li>
          <li><a href="{prefix}page/YAMBO_ALLOC_DOCUMENTATION.html" style="color: #6BA3F5;">Memory Mgmt</a></li>
        </ul>
      </div>
      <div>
        <strong style="color: #6BA3F5;">⏱️ Real-Time</strong>
        <ul style="list-style: none; padding: 8px 0 0 0; margin: 0;">
          <li><a href="{prefix}page/YAMBO_RT_THEORY_DOCUMENTATION.html" style="color: #6BA3F5;">RT Theory</a></li>
          <li><a href="{prefix}page/YAMBO_RT_QUICK_REFERENCE.html" style="color: #6BA3F5;">RT Reference</a></li>
          <li><a href="{prefix}page/YPP_RT_DOCUMENTATION.html" style="color: #6BA3F5;">YPP Tool</a></li>
        </ul>
      </div>
      <div>
        <strong style="color: #6BA3F5;">🔗 Code API</strong>
        <ul style="list-style: none; padding: 8px 0 0 0; margin: 0;">
          <li><a href="{prefix}modules/index.html" style="color: #6BA3F5;">Modules</a></li>
          <li><a href="{prefix}proc/index.html" style="color: #6BA3F5;">Procedures</a></li>
          <li><a href="{prefix}src/index.html" style="color: #6BA3F5;">Source Files</a></li>
          <li><a href="{prefix}type/index.html" style="color: #6BA3F5;">Types</a></li>
        </ul>
      </div>
    </div>
  </div>
</div>
'''
    return nav_menu

def add_menu_to_file(filepath, doc_dir):
    """Add navigation menu to HTML file."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Check if menu already exists
        if 'ford-doc-nav' in content:
            return False
        
        # Calculate depth (number of directories from doc_dir to filepath)
        rel_path = os.path.relpath(filepath, doc_dir)
        # Count slashes to determine depth - each slash means we need one level up
        depth = rel_path.count(os.sep)
        
        # Get navigation menu with correct relative paths
        nav_menu = get_nav_menu_html(depth)
        
        # Find footer or body closing tag
        if '</body>' in content:
            content = content.replace('</body>', nav_menu + '\n</body>')
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
    except Exception as e:
        print(f"Error processing {filepath}: {e}")
        return False
    
    return False

def process_directory(doc_dir):
    """Process all HTML files in documentation directory."""
    count = 0
    for root, dirs, files in os.walk(doc_dir):
        for file in files:
            if file.endswith('.html'):
                filepath = os.path.join(root, file)
                if add_menu_to_file(filepath, doc_dir):
                    count += 1
    return count

if __name__ == '__main__':
    doc_path = Path(__file__).parent.parent / 'ford_output'
    
    if not doc_path.exists():
        print(f"Documentation directory not found: {doc_path}")
        exit(1)
    
    print(f"Adding navigation menu to {doc_path}")
    count = process_directory(str(doc_path))
    print(f"✓ Updated {count} HTML files with navigation menu")
