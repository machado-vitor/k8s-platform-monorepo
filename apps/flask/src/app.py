"""
Flask Application

This is a simple Flask application that provides a REST API.
"""

from flask import Flask, jsonify, request
import os
import socket
import datetime

app = Flask(__name__)

# Configuration
DEBUG = os.environ.get('DEBUG', 'False').lower() in ('true', '1', 't')
HOST = os.environ.get('HOST', '0.0.0.0')
PORT = int(os.environ.get('PORT', 5000))


@app.route('/')
def index():
    """Root endpoint that returns basic information about the application."""
    return jsonify({
        'message': 'Welcome to the Flask API',
        'hostname': socket.gethostname(),
        'timestamp': datetime.datetime.now().isoformat(),
        'version': os.environ.get('APP_VERSION', '1.0.0')
    })


@app.route('/health')
def health():
    """Health check endpoint for Kubernetes liveness and readiness probes."""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.datetime.now().isoformat()
    })


@app.route('/api/echo', methods=['POST'])
def echo():
    """Echo endpoint that returns the JSON payload sent to it."""
    if not request.is_json:
        return jsonify({'error': 'Request must be JSON'}), 400

    data = request.get_json()
    return jsonify({
        'echo': data,
        'timestamp': datetime.datetime.now().isoformat()
    })


@app.route('/api/env')
def environment():
    """Returns information about the environment."""
    return jsonify({
        'environment': os.environ.get('ENVIRONMENT', 'development'),
        'python_version': os.environ.get('PYTHON_VERSION', '3.9'),
        'hostname': socket.gethostname(),
        'timestamp': datetime.datetime.now().isoformat()
    })


@app.errorhandler(404)
def not_found(e):
    """Handler for 404 errors."""
    return jsonify({
        'error': 'Not found',
        'path': request.path,
        'timestamp': datetime.datetime.now().isoformat()
    }), 404


@app.errorhandler(500)
def server_error(e):
    """Handler for 500 errors."""
    return jsonify({
        'error': 'Internal server error',
        'message': str(e),
        'timestamp': datetime.datetime.now().isoformat()
    }), 500


if __name__ == '__main__':
    app.run(debug=DEBUG, host=HOST, port=PORT)
