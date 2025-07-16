-- 接続確認
SELECT 'MySQL AIチャットDB作成開始' AS status;
SELECT VERSION() AS mysql_version;

-- データベースの使用
USE my_database;

-- 既存のテーブルを削除（順序に注意）
DROP TABLE IF EXISTS Memo;
DROP TABLE IF EXISTS Folder;
DROP TABLE IF EXISTS User;

-- Userテーブルの作成（MySQL版）
CREATE TABLE User (
    UserID INT AUTO_INCREMENT PRIMARY KEY,
    UserName VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Folderテーブルの作成（MySQL版）
CREATE TABLE Folder (
    FolderID INT AUTO_INCREMENT PRIMARY KEY,
    FolderName VARCHAR(100) NOT NULL,
    Date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Memoテーブルの作成（MySQL版）
CREATE TABLE Memo (
    MemoID INT AUTO_INCREMENT PRIMARY KEY,
    UserID INT NOT NULL,
    FolderID INT NOT NULL,
    Title VARCHAR(200) NOT NULL,
    Memo TEXT NOT NULL,
    Date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Listen BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- 外部キー制約
    FOREIGN KEY (UserID) REFERENCES User(UserID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (FolderID) REFERENCES Folder(FolderID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- インデックスの作成
CREATE INDEX idx_user_name ON User(UserName);
CREATE INDEX idx_folder_name ON Folder(FolderName);
CREATE INDEX idx_memo_user_id ON Memo(UserID);
CREATE INDEX idx_memo_folder_id ON Memo(FolderID);
CREATE INDEX idx_memo_date ON Memo(Date);
CREATE INDEX idx_memo_title ON Memo(Title);

-- サンプルデータの挿入
-- ユーザーデータ
INSERT INTO User (UserName) VALUES 
('田中太郎'),
('佐藤花子'),
('鈴木一郎');

-- フォルダーデータ
INSERT INTO Folder (FolderName) VALUES 
('仕事'),
('プライベート'),
('学習'),
('アイデア');

-- メモデータ
INSERT INTO Memo (UserID, FolderID, Title, Memo, Listen) VALUES 
(1, 1, '会議の議事録', '今日の会議では新しいプロジェクトについて話し合いました。', FALSE),
(1, 2, '買い物リスト', '牛乳、パン、卵を買う必要があります。', FALSE),
(2, 3, 'MySQL学習メモ', 'データベースの基本的な操作について学習しました。', TRUE),
(2, 4, '新機能のアイデア', 'チャットボットに音声認識機能を追加するアイデア', TRUE),
(3, 1, 'プロジェクト進捗', '今週のタスクを完了しました。来週は新しいタスクに取り組みます。', FALSE);

-- データベースの状態確認
SELECT 'Users' as Table_Name, COUNT(*) as Record_Count FROM User
UNION ALL
SELECT 'Folders' as Table_Name, COUNT(*) as Record_Count FROM Folder
UNION ALL
SELECT 'Memos' as Table_Name, COUNT(*) as Record_Count FROM Memo;

-- テーブル構造の確認（MySQL版）
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'my_database' 
AND TABLE_NAME IN ('User', 'Folder', 'Memo')
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- データの確認
SELECT 
    m.MemoID,
    u.UserName,
    f.FolderName,
    m.Title,
    m.Date,
    m.Listen
FROM Memo m
JOIN User u ON m.UserID = u.UserID
JOIN Folder f ON m.FolderID = f.FolderID
ORDER BY m.Date DESC;

-- インデックス確認
SHOW INDEX FROM User;
SHOW INDEX FROM Folder;
SHOW INDEX FROM Memo;

-- 完了メッセージ
SELECT 'MySQL版 AIチャットDBが正常に作成されました。' as Status;
SELECT CONCAT('テーブル数: ', COUNT(*)) AS table_summary 
FROM information_schema.tables 
WHERE table_schema = 'my_database';
