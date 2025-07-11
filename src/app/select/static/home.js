const modal = document.getElementById("createModal");
const openBtn = document.getElementById("openCreateModal");
const closeBtn = document.getElementsByClassName("close-button")[0];
const createForm = document.getElementById("createCardForm");
const cardContainer = document.querySelector(".card-container");

modal.style.display = "none";

openBtn.onclick = function() {
  modal.style.display = "flex";
}

closeBtn.onclick = function() {
  modal.style.display = "none";
}

window.onclick = function(event) {
  if (event.target == modal) {
    modal.style.display = "none";
  }
}

createForm.addEventListener('submit', async function(event) {
  event.preventDefault();

  const emoji = document.getElementById('emoji').value;
  const title = document.getElementById('title').value;

  const response = await fetch('/api/cards', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ emoji, title, source_count: 1 })
  });

  if (response.ok) {
    const newCardData = await response.json();
    const newCardElement = `
      <a href="/detail/${newCardData.id}" class="card-link">
        <div class="card">
          <div class="emoji">${newCardData.emoji}</div>
          <div class="title">${newCardData.title}</div>
          <div class="info">${newCardData.date} ・ ${newCardData.source_count}個のソース</div>
        </div>
      </a>
    `;
    cardContainer.insertAdjacentHTML('beforeend', newCardElement);
    modal.style.display = "none"; // モーダルを閉じる
    createForm.reset(); // フォームをリセット
  } else {
    alert('カードの作成に失敗しました。');
  }
});