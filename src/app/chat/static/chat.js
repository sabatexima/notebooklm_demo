// DOMが完全に読み込まれて解析された後に実行されるイベントリスナー
document.addEventListener('DOMContentLoaded', () => {
    // チャットログを表示する要素を取得
    const chatLog = document.getElementById('chat-log');
    // チャットメッセージを送信するためのフォーム要素を取得
    const chatForm = document.getElementById('chat-form');
    // ユーザーがメッセージを入力するテキストフィールド要素を取得
    const userInput = document.getElementById('user-input');

    // チャットフォームの送信イベントにイベントリスナーを追加
    chatForm.addEventListener('submit', async (e) => {
        e.preventDefault(); // フォームのデフォルトの送信動作（ページのリロード）をキャンセル
        const userMessage = userInput.value.trim(); // ユーザーの入力メッセージを取得し、前後の空白を削除

        if (userMessage) { // ユーザーの入力メッセージが空でない場合
            appendMessage(userMessage, 'user'); // ユーザーのメッセージをチャットログに追加
            userInput.value = ''; // ユーザー入力フィールドをクリア

            // '/chat/chatAI'エンドポイントにPOSTリクエストを送信
            // ユーザーのメッセージをJSON形式でサーバーに送信します。
            const response = await fetch('/chat/chatAI', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ message: userMessage }),
            });

            const data = await response.json(); // サーバーからの応答をJSONとして取得
            appendMessage(data.reply, 'ai'); // AIの応答をチャットログに追加
        }
    });

    // メッセージをチャットログに追加する関数
    function appendMessage(message, sender) {
        const messageElement = document.createElement('div'); // 新しいdiv要素を作成
        // メッセージ要素に'message'クラスと、送信者に応じたクラス（'user-message'または'ai-message'）を追加
        messageElement.classList.add('message', `${sender}-message`);
        
        const p = document.createElement('p'); // 新しいp（段落）要素を作成
        p.textContent = message; // 段落要素にメッセージテキストを設定
        messageElement.appendChild(p); // メッセージ要素に段落要素を追加

        chatLog.appendChild(messageElement); // チャットログにメッセージ要素を追加
        chatLog.scrollTop = chatLog.scrollHeight; // チャットログを一番下までスクロールして、最新のメッセージが見えるようにする
    }
});
