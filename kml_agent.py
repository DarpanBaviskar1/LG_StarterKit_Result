"""
KML Agent - Generate KML from natural language using Google Gemini API

This script uses the Google Gemini API to convert natural language prompts
into valid KML (Keyhole Markup Language) for Liquid Galaxy visualization.

Requirements:
    pip install google-generativeai
    
Environment:
    Set GOOGLE_API_KEY environment variable with your Gemini API key
    Or pass api_key parameter to KMLAgent class
"""

import os
import json
import re
from typing import Optional
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

class KMLAgent:
    """Generate KML from natural language using Gemini API."""
    
    def __init__(self, api_key: Optional[str] = None):
        """
        Initialize the KML Agent.
        
        Args:
            api_key: Google Gemini API key. If not provided, uses GOOGLE_API_KEY env var.
        
        Raises:
            ValueError: If no API key is provided or found in environment.
        """
        key = api_key or os.getenv('GOOGLE_API_KEY')
        if not key:
            raise ValueError(
                'Google API key required. Pass api_key parameter or set GOOGLE_API_KEY env var.'
            )
        
        genai.configure(api_key=key)
        self.model = genai.GenerativeModel('gemini-3-flash-preview')
        
    @staticmethod
    def _build_system_prompt() -> str:
        """Build the system prompt for KML generation."""
        return """You are a KML (Keyhole Markup Language) generation expert for Google Earth and Liquid Galaxy.

CRITICAL: Output ONLY the KML XML code. No explanations, no markdown, no code blocks, no additional text whatsoever.

RULES:
1. XML declaration: <?xml version="1.0" encoding="UTF-8"?>
2. Namespaces: xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2"
3. For fly-to: use gx:Tour with gx:FlyTo for animations
4. Camera elements must include: longitude, latitude, altitude, heading, tilt, roll, altitudeMode
5. Coordinates: latitude [-90, 90], longitude [-180, 180]
6. Defaults: altitude=1000, heading=0, tilt=45, roll=0
7. Escape XML: &, <, >, ", '
8. Multiple stops: use multiple gx:FlyTo elements in sequence
9. Wrap in KML Document tags
10. Output: ONLY valid KML, nothing else

COORDINATES:
- New York: 40.7128, -74.0060
- Eiffel Tower: 48.8584, 2.2945
- Tokyo: 35.6762, 139.6503
- Sydney: -33.8568, 151.2153

Generate ONLY KML. No extra text."""

    def generate_kml(self, prompt: str) -> str:
        """
        Generate KML from a natural language prompt using Gemini.
        
        Args:
            prompt: Natural language description of the KML to generate
                   E.g., "Fly to Eiffel Tower and show a tour of Paris"
        
        Returns:
            Valid KML string
        
        Raises:
            ValueError: If prompt is empty
            Exception: If API call fails or invalid KML is generated
        """
        if not prompt or not prompt.strip():
            raise ValueError('Prompt cannot be empty')
        
        try:
            system_prompt = self._build_system_prompt()
            
            # Call Gemini API
            response = self.model.generate_content(
                f"{system_prompt}\n\nUser request: {prompt}",
                generation_config=genai.types.GenerationConfig(
                    temperature=0.3,  # Lower temperature for consistency
                    max_output_tokens=4096,
                )
            )
            
            if not response.text:
                raise Exception('No response from Gemini API')
            
            kml = response.text.strip()
            
            # Remove markdown code blocks if present
            if kml.startswith('```xml'):
                kml = kml[6:]
            if kml.startswith('```'):
                kml = kml[3:]
            if kml.endswith('```'):
                kml = kml[:-3]
            
            kml = kml.strip()
            
            # Validate KML
            if not self._is_valid_kml(kml):
                raise Exception('Generated KML failed validation')
            
            return kml
            
        except Exception as e:
            raise Exception(f'KML generation failed: {str(e)}')
    
    @staticmethod
    def _is_valid_kml(kml: str) -> bool:
        """
        Validate that the KML has required elements.
        
        Args:
            kml: KML string to validate
        
        Returns:
            True if KML has required structure, False otherwise
        """
        required_elements = [
            '<?xml',
            '<kml',
            '<Document>',
            '</Document>',
            '</kml>',
        ]
        
        for element in required_elements:
            if element not in kml:
                print(f'Warning: Missing required KML element: {element}')
                return False
        
        # Check for at least one of: LookAt, Camera, FlyTo, Placemark
        has_content = any(elem in kml for elem in [
            '<Camera>',
            '<LookAt>',
            '<gx:FlyTo>',
            '<Placemark>',
            '<LineString>',
            '<Polygon>',
        ])
        
        if not has_content:
            print('Warning: KML missing geographic content')
            return False
        
        return True


def main():
    """Main entry point for interactive KML generation."""
    import sys
    
    # Get API key
    api_key = os.getenv('GOOGLE_API_KEY')
    if not api_key:
        print('Error: GOOGLE_API_KEY environment variable not set')
        print('Set it with: $env:GOOGLE_API_KEY = "your-api-key"')
        sys.exit(1)
    
    # Initialize agent
    agent = KMLAgent(api_key=api_key)
    
    print('\n' + '='*60)
    print('KML Agent - Generate KML from Natural Language')
    print('='*60)
    print('Type "exit" to quit\n')
    
    while True:
        try:
            # Get user input
            user_prompt = input('Enter your prompt: ').strip()
            
            # Check for exit
            if user_prompt.lower() in ['exit', 'quit', 'q']:
                print('Goodbye!')
                break
            
            # Validate input
            if not user_prompt:
                print('Error: Please enter a valid prompt\n')
                continue
            
            print('\nGenerating KML...')
            
            # Generate KML
            kml = agent.generate_kml(user_prompt)
            
            print('\n' + '='*60)
            print('Generated KML:')
            print('='*60)
            print(kml)
            print('='*60 + '\n')
            
            # Ask to save
            save_choice = input('Save to file? (y/n): ').strip().lower()
            if save_choice == 'y':
                filename = input('Filename (default: output.kml): ').strip()
                if not filename:
                    filename = 'output.kml'
                
                with open(filename, 'w') as f:
                    f.write(kml)
                print(f'✓ Saved to: {filename}\n')
            
        except KeyboardInterrupt:
            print('\n\nInterrupted by user. Goodbye!')
            break
        except Exception as e:
            print(f'Error: {e}\n')


if __name__ == '__main__':
    main()
