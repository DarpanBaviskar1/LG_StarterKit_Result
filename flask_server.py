"""
Flask Server Wrapper for KML Agent Python Script

This server provides HTTP endpoints for the Flutter app to interact with the KML Agent.

Requirements:
    pip install flask google-generativeai python-dotenv
    
Usage:
    python flask_server.py
    
Then the server will be available at http://localhost:8000
"""

from flask import Flask, request, jsonify
import os
import sys
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Import the KML Agent
from kml_agent import KMLAgent

app = Flask(__name__)

# Initialize the KML Agent
try:
    agent = KMLAgent(api_key=os.getenv('GOOGLE_API_KEY'))
    print('✓ KML Agent initialized successfully')
except ValueError as e:
    print(f'✗ Failed to initialize KML Agent: {e}')
    print('Set GOOGLE_API_KEY environment variable:')
    print('  Windows PowerShell: $env:GOOGLE_API_KEY = "your-api-key"')
    print('  Linux/macOS: export GOOGLE_API_KEY="your-api-key"')
    sys.exit(1)


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy',
        'service': 'KML Agent Server',
        'version': '1.0'
    })


@app.route('/generate-kml', methods=['POST'])
def generate_kml():
    """
    Generate KML from a natural language prompt.
    
    Request JSON:
        {
            "query": "Fly to Eiffel Tower"
        }
    
    Response JSON:
        {
            "kml": "<?xml version=\"1.0\"... </kml>"
        }
    
    Error Response:
        {
            "error": "Error message"
        }
    """
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'Request body must be JSON'}), 400
        
        prompt = data.get('query', '').strip()
        
        if not prompt:
            return jsonify({'error': 'Query parameter is required'}), 400
        
        print(f'📝 Generating KML for: "{prompt}"')
        
        # Generate KML
        kml = agent.generate_kml(prompt)
        
        print(f'✓ KML generated successfully ({len(kml)} chars)')
        
        return jsonify({'kml': kml}), 200
        
    except Exception as e:
        error_msg = str(e)
        print(f'✗ Error generating KML: {error_msg}')
        return jsonify({'error': error_msg}), 500


@app.route('/generate-kml-batch', methods=['POST'])
def generate_kml_batch():
    """
    Generate KML for multiple prompts in batch.
    
    Request JSON:
        {
            "queries": ["Fly to Eiffel Tower", "Fly to Big Ben"]
        }
    
    Response JSON:
        {
            "results": [
                {"query": "...", "kml": "..."},
                {"query": "...", "kml": "..."}
            ],
            "failed": [
                {"query": "...", "error": "..."}
            ]
        }
    """
    try:
        data = request.get_json()
        
        if not data or 'queries' not in data:
            return jsonify({'error': 'queries array is required'}), 400
        
        queries = data.get('queries', [])
        
        if not isinstance(queries, list) or not queries:
            return jsonify({'error': 'queries must be a non-empty array'}), 400
        
        results = []
        failed = []
        
        for prompt in queries:
            try:
                prompt = str(prompt).strip()
                if not prompt:
                    continue
                
                print(f'📝 Batch: Generating KML for: "{prompt}"')
                kml = agent.generate_kml(prompt)
                results.append({
                    'query': prompt,
                    'kml': kml
                })
            except Exception as e:
                failed.append({
                    'query': prompt,
                    'error': str(e)
                })
        
        print(f'✓ Batch complete: {len(results)} successful, {len(failed)} failed')
        
        return jsonify({
            'results': results,
            'failed': failed
        }), 200
        
    except Exception as e:
        error_msg = str(e)
        print(f'✗ Batch error: {error_msg}')
        return jsonify({'error': error_msg}), 500


@app.route('/validate-kml', methods=['POST'])
def validate_kml():
    """
    Validate KML content.
    
    Request JSON:
        {
            "kml": "<?xml version=\"1.0\"... </kml>"
        }
    
    Response JSON:
        {
            "valid": true/false,
            "errors": []
        }
    """
    try:
        data = request.get_json()
        
        if not data or 'kml' not in data:
            return jsonify({'error': 'kml parameter is required'}), 400
        
        kml = data.get('kml', '').strip()
        is_valid = KMLAgent._is_valid_kml(kml)
        
        return jsonify({
            'valid': is_valid,
            'length': len(kml)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors."""
    return jsonify({
        'error': 'Endpoint not found',
        'available_endpoints': [
            'GET /health',
            'POST /generate-kml',
            'POST /generate-kml-batch',
            'POST /validate-kml'
        ]
    }), 404


@app.errorhandler(500)
def server_error(error):
    """Handle 500 errors."""
    return jsonify({'error': 'Internal server error'}), 500


if __name__ == '__main__':
    print('\n' + '='*60)
    print('KML Agent Flask Server')
    print('='*60)
    print('\nEndpoints:')
    print('  GET  http://localhost:8000/health')
    print('  POST http://localhost:8000/generate-kml')
    print('  POST http://localhost:8000/generate-kml-batch')
    print('  POST http://localhost:8000/validate-kml')
    print('\nServer starting on http://localhost:8000')
    print('Press Ctrl+C to stop')
    print('='*60 + '\n')
    
    # Run the Flask app
    app.run(
        host='127.0.0.1',
        port=8000,
        debug=True,
        use_reloader=True
    )
