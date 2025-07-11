// 新規作成モーダル関連のDOM要素を取得
const createModal = document.getElementById("createModal"); // 新規メモ作成用のモーダルウィンドウ
const openCreateBtn = document.getElementById("openCreateModal"); // 新規作成モーダルを開くボタン
const closeCreateBtn = document.getElementById("closeCreateModal"); // 新規作成モーダルを閉じるボタン
const createMemoForm = document.getElementById("createMemoForm"); // 新規メモ作成フォーム
const createTitleInput = document.getElementById("createTitle"); // 新規メモのタイトル入力フィールド
const createContentInput = document.getElementById("createContent"); // 新規メモのコンテンツ入力フィールド
const createAskGeminiCheckbox = document.getElementById("createAskGemini"); // Geminiに質問するかどうかのチェックボックス

// 編集モーダル関連のDOM要素を取得
const editModal = document.getElementById("editModal"); // メモ編集用のモーダルウィンドウ
const closeEditBtn = document.getElementById("closeEditModal"); // 編集モーダルを閉じるボタン
const editMemoForm = document.getElementById("editMemoForm"); // メモ編集フォーム
const editMemoIdInput = document.getElementById("editMemoId"); // 編集中のメモのIDを保持する隠しフィールド
const editTitleInput = document.getElementById("editTitle"); // 編集中のメモのタイトル入力フィールド
const editContentInput = document.getElementById("editContent"); // 編集中のメモのコンテンツ入力フィールド
const editAskGeminiCheckbox = document.getElementById("editAskGemini"); // 編集中のメモでGeminiに質問するかどうかのチェックボックス
const deleteMemoBtn = document.getElementById("deleteMemoBtn"); // メモ削除ボタン

const cardContainer = document.querySelector(".card-container"); // メモカードが追加されるコンテナ

// 初期状態で新規作成モーダルと編集モーダルを非表示に設定
createModal.style.display = "none";
editModal.style.display = "none";

// 新規作成ボタンがクリックされた時に、新規作成モーダルを表示
openCreateBtn.onclick = function() {
    createModal.style.display = "flex";
}

// 新規作成モーダルの閉じるボタンがクリックされた時に、モーダルを非表示に設定
closeCreateBtn.onclick = function() {
    createModal.style.display = "none";
}

// 編集モーダルの閉じるボタンがクリックされた時に、モーダルを非表示に設定
closeEditBtn.onclick = function() {
    editModal.style.display = "none";
}

// ウィンドウのどこかがクリックされた時に、モーダルの外側がクリックされたかを判定し、モーダルを閉じる
window.onclick = function(event) {
    if (event.target == createModal) {
        createModal.style.display = "none";
    } else if (event.target == editModal) {
        editModal.style.display = "none";
    }
}

// 新規メモ作成フォームが送信された時のイベントリスナー
createMemoForm.addEventListener('submit', async function(event) {
    event.preventDefault(); // フォームのデフォルトの送信動作をキャンセル

    // 入力フィールドからタイトル、コンテンツ、Geminiに質問するかどうかの値を取得
    const title = createTitleInput.value;
    const content = createContentInput.value;
    const askGemini = createAskGeminiCheckbox.checked;

    // '/chat/api/memos'エンドポイントにPOSTリクエストを送信し、新しいメモを作成
    const response = await fetch('/chat/api/memos', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ title, content, ask_gemini: askGemini })
    });

    if (response.ok) { // レスポンスが成功した場合
        const newMemoData = await response.json(); // レスポンスのJSONデータを取得
        // 新しく作成されたメモカードのHTML要素を生成
        const newMemoElement = `
            <div class="card-link" data-memo-id="${newMemoData.id}" data-memo-title="${newMemoData.title}" data-memo-content="${newMemoData.content}" data-memo-ask-gemini="${newMemoData.ask_gemini}">
                <div class="card">
                    <div class="title">${newMemoData.title}</div>
                    <div class="content">${newMemoData.content.length > 40 ? newMemoData.content.substring(0, 40) + '...' : newMemoData.content}</div>
                    <div class="info">${newMemoData.date}</div>
                    ${newMemoData.ask_gemini ? '<div class="gemini-status">Geminiに質問済み</div>' : ''}
                </div>
            </div>
        `;
        cardContainer.insertAdjacentHTML('beforeend', newMemoElement); // 生成したメモカードをコンテナに追加
        createModal.style.display = "none"; // 新規作成モーダルを非表示に設定
        createMemoForm.reset(); // フォームの入力内容をリセット
        attachCardClickListeners(); // 新しく追加されたカードにもクリックイベントリスナーを付与
    } else { // メモの作成に失敗した場合
        alert('メモの作成に失敗しました。'); // エラーメッセージを表示
    }
});

// カードクリックで編集モーダルを開く関数
function attachCardClickListeners() {
    // すべてのメモカード（.card-link）に対してループ処理
    document.querySelectorAll('.card-link').forEach(cardLink => {
        cardLink.onclick = function() { // 各カードがクリックされた時のイベントハンドラーを設定
            // クリックされたカードのdata属性からメモの情報を取得
            const memoId = this.dataset.memoId;
            const memoTitle = this.dataset.memoTitle;
            const memoContent = this.dataset.memoContent;
            const memoAskGemini = this.dataset.memoAskGemini === 'true'; // 文字列をboolean型に変換

            // 取得した情報を編集モーダルの入力フィールドに設定
            editMemoIdInput.value = memoId;
            editTitleInput.value = memoTitle;
            editContentInput.value = memoContent;
            editAskGeminiCheckbox.checked = memoAskGemini;
            editModal.style.display = "flex"; // 編集モーダルを表示
        };
    });
}

attachCardClickListeners(); // ページロード時に既存のメモカードにクリックイベントリスナーを付与

// メモ編集フォームが送信された時のイベントリスナー
editMemoForm.addEventListener('submit', async function(event) {
    event.preventDefault(); // フォームのデフォルトの送信動作をキャンセル

    // 編集モーダルの入力フィールドからメモの情報を取得
    const memoId = editMemoIdInput.value;
    const title = editTitleInput.value;
    const content = editContentInput.value;
    const askGemini = editAskGeminiCheckbox.checked;

    // `/chat/api/memos/${memoId}`エンドポイントにPUTリクエストを送信し、メモを更新
    const response = await fetch(`/chat/api/memos/${memoId}`, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ title, content, ask_gemini: askGemini })
    });

    if (response.ok) { // レスポンスが成功した場合
        location.reload(); // ページをリロードして最新のデータを表示
    } else { // メモの更新に失敗した場合
        alert('メモの更新に失敗しました。'); // エラーメッセージを表示
    }
});

// メモ削除ボタンがクリックされた時のイベントリスナー
deleteMemoBtn.addEventListener('click', async function() {
    const memoId = editMemoIdInput.value; // 編集中のメモのIDを取得
    if (confirm('本当にこのメモを削除しますか？')) { // 削除確認のダイアログを表示
        // `/chat/api/memos/${memoId}`エンドポイントにDELETEリクエストを送信し、メモを削除
        const response = await fetch(`/chat/api/memos/${memoId}`, {
            method: 'DELETE'
        });

        if (response.ok) { // レスポンスが成功した場合
            location.reload(); // ページをリロードして最新のデータを表示
        } else { // メモの削除に失敗した場合
            alert('メモの削除に失敗しました。'); // エラーメッセージを表示
        }
    }
});