# 必要なライブラリをインポートする
import json
import os


# 設定を管理するクラス
class Config:
    
    # 初期化
    def __init__(self, filepath: str='config.json'):
        # 設定ファイルのパス
        self.filepath = filepath
        # 設定データを格納する辞書
        self.data = {}
        
        # 設定ファイルを読み込む
        self.load()
    
    
    # 設定ファイルを読み込む
    def load(self):
        """
        設定ファイルを読み込む
        """
        
        # 設定ファイルが存在する場合
        if os.path.isfile(self.filepath):
            # ファイルを開いてJSONデータを読み込む
            with open(self.filepath, 'r') as f:
                self.data = json.load(f)
        # 設定ファイルが存在しない場合
        else:
            # デフォルト設定を読み込む
            self.load_default()
            # 設定を保存する
            self.save()
    
    
    # 設定ファイルを保存する
    def save(self):
        """
        設定ファイルを保存する
        """
        
        # ファイルを開いてJSONデータを書き込む
        with open(self.filepath, 'w') as f:
            json.dump(self.data, f, ensure_ascii=False, indent=4, sort_keys=True, separators=(',', ': '))
            # ファイルのパーミッションを777に変更する
            os.chmod(self.filepath, 0o777)
    
    
    # 設定を取得する
    def get(self, key: str):
        """
        設定を取得
        
        Args:
            key(str): 設定キー
        """
        
        # キーを.で分割する
        keys = key.split('.')
        # 設定データを取得する
        value = self.data
        
        # キーを順番に辿って値を取得する
        for k in keys:
            if k in value:
                value = value[k]
        
        # 値を返す
        return value
    
    
    # デフォルト設定を読み込む
    def load_default(self):
        """
        デフォルト設定を読み込む
        """
        
        # デフォルト設定ファイルを開いてJSONデータを読み込む
        with open('default_config.json', 'r') as f:
            self.data = json.load(f)