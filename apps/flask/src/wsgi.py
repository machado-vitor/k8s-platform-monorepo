"""
WSGI Entry Point

This file serves as the entry point for WSGI servers like Gunicorn.
"""

from app import app

if __name__ == "__main__":
    app.run()
