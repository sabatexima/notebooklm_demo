from flask import Blueprint,render_template,Flask, request, jsonify

sample = Blueprint("sample", __name__)

@sample.route("/")
def index():
    print("sample.index")
    return render_template('index.html')
