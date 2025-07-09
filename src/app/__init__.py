from flask import Flask
from app.views.sample import sample


def get_app():
    app = Flask(__name__)
    _register_blueprint(app)
    return app


def _register_blueprint(app):
    app.register_blueprint(sample)
