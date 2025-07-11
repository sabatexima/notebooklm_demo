from flask import Blueprint,render_template,Flask, request, jsonify
import app.views.chatModel as chatModel

sample = Blueprint("sample", __name__)


@sample.route('/')
def index():
    return render_template('index.html')

@sample.route('/chat', methods=['POST'])
def chat():
    user_message = request.json.get('message')
    # ここでAIのロジックを呼び出す（今回はオウム返し）
    a = chatModel.chat()
    ai_message = a.chat(user_message)

    return jsonify({'reply': ai_message})
