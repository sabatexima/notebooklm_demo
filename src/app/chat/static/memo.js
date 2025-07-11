// 新規作成モーダル関連
const createModal = document.getElementById("createModal");
const openCreateBtn = document.getElementById("openCreateModal");
const closeCreateBtn = document.getElementById("closeCreateModal");
const createMemoForm = document.getElementById("createMemoForm");
const createTitleInput = document.getElementById("createTitle");
const createContentInput = document.getElementById("createContent");
const createAskGeminiCheckbox = document.getElementById("createAskGemini");

// 編集モーダル関連
const editModal = document.getElementById("editModal");
const closeEditBtn = document.getElementById("closeEditModal");
const editMemoForm = document.getElementById("editMemoForm");
const editMemoIdInput = document.getElementById("editMemoId");
const editTitleInput = document.getElementById("editTitle");
const editContentInput = document.getElementById("editContent");
const editAskGeminiCheckbox = document.getElementById("editAskGemini");
const deleteMemoBtn = document.getElementById("deleteMemoBtn");

const cardContainer = document.querySelector(".card-container");

createModal.style.display = "none";
editModal.style.display = "none";

openCreateBtn.onclick = function() {
    createModal.style.display = "flex";
}

closeCreateBtn.onclick = function() {
    createModal.style.display = "none";
}

closeEditBtn.onclick = function() {
    editModal.style.display = "none";
}

window.onclick = function(event) {
    if (event.target == createModal) {
        createModal.style.display = "none";
    } else if (event.target == editModal) {
        editModal.style.display = "none";
    }
}

// 新規メモ作成処理
createMemoForm.addEventListener('submit', async function(event) {
    event.preventDefault();

    const title = createTitleInput.value;
    const content = createContentInput.value;
    const askGemini = createAskGeminiCheckbox.checked;

    const response = await fetch('/chat/api/memos', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ title, content, ask_gemini: askGemini })
    });

    if (response.ok) {
        const newMemoData = await response.json();
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
        cardContainer.insertAdjacentHTML('beforeend', newMemoElement);
        createModal.style.display = "none";
        createMemoForm.reset();
        attachCardClickListeners(); // 新しく追加されたカードにもイベントリスナーを付ける
    } else {
        alert('メモの作成に失敗しました。');
    }
});

// カードクリックで編集モーダルを開く
function attachCardClickListeners() {
    document.querySelectorAll('.card-link').forEach(cardLink => {
        cardLink.onclick = function() {
            const memoId = this.dataset.memoId;
            const memoTitle = this.dataset.memoTitle;
            const memoContent = this.dataset.memoContent;
            const memoAskGemini = this.dataset.memoAskGemini === 'true'; // 文字列をbooleanに変換

            editMemoIdInput.value = memoId;
            editTitleInput.value = memoTitle;
            editContentInput.value = memoContent;
            editAskGeminiCheckbox.checked = memoAskGemini;
            editModal.style.display = "flex";
        };
    });
}

attachCardClickListeners(); // ページロード時に既存のカードにイベントリスナーを付ける

// メモ編集処理
editMemoForm.addEventListener('submit', async function(event) {
    event.preventDefault();

    const memoId = editMemoIdInput.value;
    const title = editTitleInput.value;
    const content = editContentInput.value;
    const askGemini = editAskGeminiCheckbox.checked;

    const response = await fetch(`/chat/api/memos/${memoId}`, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ title, content, ask_gemini: askGemini })
    });

    if (response.ok) {
        // ページをリロードして最新のデータを表示
        location.reload();
    } else {
        alert('メモの更新に失敗しました。');
    }
});

// メモ削除処理
deleteMemoBtn.addEventListener('click', async function() {
    const memoId = editMemoIdInput.value;
    if (confirm('本当にこのメモを削除しますか？')) {
        const response = await fetch(`/chat/api/memos/${memoId}`, {
            method: 'DELETE'
        });

        if (response.ok) {
            // ページをリロードして最新のデータを表示
            location.reload();
        } else {
            alert('メモの削除に失敗しました。');
        }
    }
});