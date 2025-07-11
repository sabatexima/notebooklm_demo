
// DOMが読み込まれたら実行
document.addEventListener('DOMContentLoaded', () => {
    // チャットログ、チャットフォーム、ユーザー入力の要素を取得
    const chatLog = document.getElementById('chat-log');
    const chatForm = document.getElementById('chat-form');
    const userInput = document.getElementById('user-input');

    // チャットフォームの送信イベントをリッスン
    chatForm.addEventListener('submit', async (e) => {
        // デフォルトの送信動作をキャンセル
        e.preventDefault();
        // ユーザーの入力を取得
        const userMessage = userInput.value.trim();

        // ユーザーの入力がある場合
        if (userMessage) {
            // ユーザーのメッセージをチャットログに追加
            appendMessage(userMessage, 'user');
            // ユーザーの入力をクリア
            userInput.value = '';

            // サーバーにチャットメッセージを送信
            const response = await fetch('/chat', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ message: userMessage }),
            });

            // サーバーからの応答をJSONとして取得
            const data = await response.json();
            // AIの応答をチャットログに追加
            appendMessage(data.reply, 'ai');
        }
    });

    // メッセージをチャットログに追加する関数
    function appendMessage(message, sender) {
        // 新しいメッセージ要素を作成
        const messageElement = document.createElement('div');
        // メッセージ要素にクラスを追加
        messageElement.classList.add('message', `${sender}-message`);
        
        // 新しい段落要素を作成
        const p = document.createElement('p');
        // 段落要素にメッセージを設定
        p.textContent = message;
        // メッセージ要素に段落要素を追加
        messageElement.appendChild(p);

        // チャットログにメッセージ要素を追加
        chatLog.appendChild(messageElement);
        // チャットログを一番下までスクロール
        chatLog.scrollTop = chatLog.scrollHeight;
    }
});
