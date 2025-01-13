from flask import Flask, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}}) # Allow CORS for all domains on all routes

@app.route('/')
def home():
    return jsonify(message="Hello from your Custom API!", status="success")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)