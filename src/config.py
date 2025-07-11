# 必要なライブラリをインポート
import json
import os

# 設定を管理するクラス
class Config:
    
    # 初期化
    # Configクラスの新しいインスタンスが作成される際に呼び出されます。
    def __init__(self, filepath: str='config.json'):
        # 設定ファイルのパスを保存します。
        self.filepath = filepath
        # 設定データを格納する辞書を初期化します。
        self.data = {}
        # インスタンス作成時に設定ファイルを読み込みます。
        self.load()
    
    
    # 設定ファイルを読み込む
    def load(self):
        """
        設定ファイルを読み込みます。
        """
        
        # 設定ファイルが存在するか確認します。
        if os.path.isfile(self.filepath):
            # ファイルが存在する場合、JSONデータを読み込みます。
            with open(self.filepath, 'r') as f:
                self.data = json.load(f)
        # 設定ファイルが存在しない場合
        else:
            # デフォルト設定を読み込み、保存します。
            self.load_default()
            self.save()
    
    
    # 設定ファイルを保存する
    def save(self):
        """
        設定ファイルを保存します。
        """
        
        # JSONデータをファイルに書き込みます。
        with open(self.filepath, 'w') as f:
            json.dump(self.data, f, ensure_ascii=False, indent=4, sort_keys=True, separators=(',', ': '))
            # ファイルのパーミッションを設定します。
            os.chmod(self.filepath, 0o777)
    
    
    # 設定を取得する
    def get(self, key: str):
        """
        指定されたキーの設定値を取得します。
        キーはドット区切りで階層を指定できます（例: "api.googleApiKey"）。
        """
        
        # キーをドットで分割し、階層を辿って値を取得します。
        keys = key.split('.')
        value = self.data
        
        for k in keys:
            if k in value:
                value = value[k]
            else:
                break
        
        return value
    
    
    # デフォルト設定を読み込む
    def load_default(self):
        """
        'default_config.json'からデフォルト設定を読み込みます。
        """
        
        # デフォルト設定ファイルを開いてJSONデータを読み込みます。
        with open('default_config.json', 'r') as f:
            self.data = json.load(f)