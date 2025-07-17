// DOM要素の取得
const modal = document.getElementById("createModal"); // 新規作成モーダル要素
const openBtn = document.getElementById("openCreateModal"); // 新規作成ボタン要素
const closeBtn = document.getElementsByClassName("close-button")[0]; // モーダルを閉じるボタン要素
const createForm = document.getElementById("createCardForm"); // カード作成フォーム要素
const cardContainer = document.querySelector(".card-container"); // カードを格納するコンテナ要素

// 初期状態でモーダルを非表示に設定
modal.style.display = "none";

// 新規作成ボタンがクリックされた時の処理
// モーダルを表示します。
openBtn.onclick = function() {
  modal.style.display = "flex";
}

// 閉じるボタンがクリックされた時の処理
// モーダルを非表示にします。
closeBtn.onclick = function() {
  modal.style.display = "none";
}

// ウィンドウのどこかがクリックされた時の処理
// クリックされた要素がモーダル自身であれば、モーダルを非表示にします。
window.onclick = function(event) {
  if (event.target == modal) {
    modal.style.display = "none";
  }
}

// カード作成フォームが送信された時の処理
createForm.addEventListener('submit', async function(event) {
  // フォームのデフォルトの送信動作（ページのリロード）をキャンセル
  event.preventDefault();

  // 絵文字とタイトル入力フィールドの値を取得
  const emoji = document.getElementById('emoji').value;
  const title = document.getElementById('title').value;

  // '/api/cards'エンドポイントにPOSTリクエストを送信
  // 新しいカードデータ（絵文字、タイトル、ソース数）をJSON形式で送信します。
  const response = await fetch('/select/api/cards', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ emoji, title })
  });

  // レスポンスが成功（HTTPステータスコードが200番台）した場合の処理
  if (response.ok) {
    // レスポンスのJSONデータを取得
    const newCardData = await response.json();
    // 新しく作成されたカードのHTML要素をテンプレートリテラルで生成
    const newCardElement = document.createElement('div');
    newCardElement.classList.add('card');
    newCardElement.dataset.cardId = newCardData.id;
    newCardElement.innerHTML = `
      <button class="delete-button">&times;</button>
      <a href="/chat/memo?title=${encodeURIComponent(newCardData.id)}" class="card-link">
        <div class="emoji">${newCardData.emoji}</div>
        <div class="title">${newCardData.title}</div>
        <div class="info">${newCardData.date}</div>
      </a>
    `;
    // 生成したカード要素をカードコンテナの末尾に追加
    cardContainer.appendChild(newCardElement);
    // 新しく追加したカードの削除ボタンにもイベントリスナーを追加
    newCardElement.querySelector('.delete-button').addEventListener('click', async (event) => {
      event.preventDefault();
      event.stopPropagation();

      const card = event.target.closest('.card');
      const cardId = card.dataset.cardId;

      if (confirm('本当にこのカードを削除しますか？')) {
        const response = await fetch(`/select/api/cards/${cardId}`, {
          method: 'DELETE'
        });

        if (response.ok) {
          card.remove();
        } else {
          alert('カードの削除に失敗しました。');
        }
      }
    });
    // モーダルを非表示に設定
    modal.style.display = "none";
    // フォームの入力内容をリセット
    createForm.reset();
  } else {
    // カードの作成に失敗した場合、アラートを表示
    alert('カードの作成に失敗しました。');
  }
});

// 削除ボタンにイベントリスナーを追加する関数
function addDeleteEventListeners() {
  document.querySelectorAll('.delete-button').forEach(button => {
    button.addEventListener('click', async (event) => {
      event.preventDefault(); // リンクの遷移を防ぐ
      event.stopPropagation(); // 親要素へのイベント伝播を防ぐ

      const card = button.closest('.card');
      const cardId = card.dataset.cardId;

      if (confirm('本当にこのカードを削除しますか？')) {
        const response = await fetch(`/select/api/cards/${cardId}`, {
          method: 'DELETE'
        });

        if (response.ok) {
          card.remove();
        } else {
          alert('カードの削除に失敗しました。');
        }
      }
    });
  });
}

// 初期表示時に削除ボタンにイベントリスナーを追加
addDeleteEventListeners();