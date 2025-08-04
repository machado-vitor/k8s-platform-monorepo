"""
Basic Tests for Flask Application

This file contains basic tests for the Flask application.
"""

import sys
import os
import json
import unittest

# Add the src directory to the path so we can import the app
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../src')))

from app import app


class BasicTestCase(unittest.TestCase):
    """Basic test cases for the Flask application."""

    def setUp(self):
        """Set up the test client."""
        self.app = app.test_client()
        self.app.testing = True

    def test_index(self):
        """Test the index endpoint."""
        response = self.app.get('/')
        data = json.loads(response.data)

        self.assertEqual(response.status_code, 200)
        self.assertIn('message', data)
        self.assertIn('hostname', data)
        self.assertIn('timestamp', data)
        self.assertIn('version', data)

    def test_health(self):
        """Test the health endpoint."""
        response = self.app.get('/health')
        data = json.loads(response.data)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(data['status'], 'healthy')
        self.assertIn('timestamp', data)

    def test_echo(self):
        """Test the echo endpoint."""
        test_data = {'test': 'data', 'number': 42}
        response = self.app.post('/api/echo',
                                json=test_data,
                                content_type='application/json')
        data = json.loads(response.data)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(data['echo'], test_data)
        self.assertIn('timestamp', data)

    def test_echo_bad_request(self):
        """Test the echo endpoint with a bad request."""
        response = self.app.post('/api/echo',
                                data='not json',
                                content_type='text/plain')
        data = json.loads(response.data)

        self.assertEqual(response.status_code, 400)
        self.assertIn('error', data)

    def test_environment(self):
        """Test the environment endpoint."""
        response = self.app.get('/api/env')
        data = json.loads(response.data)

        self.assertEqual(response.status_code, 200)
        self.assertIn('environment', data)
        self.assertIn('python_version', data)
        self.assertIn('hostname', data)
        self.assertIn('timestamp', data)

    def test_not_found(self):
        """Test a 404 error."""
        response = self.app.get('/nonexistent')
        data = json.loads(response.data)

        self.assertEqual(response.status_code, 404)
        self.assertEqual(data['error'], 'Not found')
        self.assertEqual(data['path'], '/nonexistent')
        self.assertIn('timestamp', data)


if __name__ == '__main__':
    unittest.main()
